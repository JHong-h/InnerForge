use serde::Serialize;
use std::process::Command;

const CURRENT_VERSION: &str = "1.0.0";
const GITHUB_REPO: &str = "JHong-h/InnerForge";

#[derive(Serialize)]
pub struct UpdateInfo {
    pub has_update: bool,
    pub version: String,
    pub download_url: String,
}

#[tauri::command]
pub async fn check_for_update() -> Result<UpdateInfo, String> {
    let url = format!("https://api.github.com/repos/{}/releases/latest", GITHUB_REPO);
    let client = reqwest::Client::new();
    let resp = client
        .get(&url)
        .header("User-Agent", "InnerForge")
        .send()
        .await
        .map_err(|e| format!("网络请求失败: {}", e))?;

    if !resp.status().is_success() {
        return Err("获取版本信息失败".into());
    }

    let data: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
    let tag = data["tag_name"].as_str().unwrap_or("").trim_start_matches('v');

    if tag.is_empty() || tag == CURRENT_VERSION {
        return Ok(UpdateInfo {
            has_update: false,
            version: CURRENT_VERSION.into(),
            download_url: String::new(),
        });
    }

    // Find the dmg asset
    let download_url = data["assets"]
        .as_array()
        .and_then(|assets| {
            assets.iter().find_map(|a| {
                let name = a["name"].as_str().unwrap_or("");
                if name.ends_with(".dmg") {
                    a["browser_download_url"].as_str().map(|s| s.to_string())
                } else {
                    None
                }
            })
        })
        .unwrap_or_default();

    Ok(UpdateInfo {
        has_update: true,
        version: tag.into(),
        download_url,
    })
}

#[tauri::command]
pub async fn download_and_install_update(download_url: String) -> Result<(), String> {
    if download_url.is_empty() {
        return Err("下载链接为空".into());
    }

    let client = reqwest::Client::new();
    let resp = client
        .get(&download_url)
        .header("User-Agent", "InnerForge")
        .send()
        .await
        .map_err(|e| format!("下载失败: {}", e))?;

    if !resp.status().is_success() {
        return Err("下载失败".into());
    }

    let bytes = resp.bytes().await.map_err(|e| format!("读取数据失败: {}", e))?;

    let tmp_dir = std::env::temp_dir();
    let dmg_path = tmp_dir.join("InnerForge_update.dmg");
    std::fs::write(&dmg_path, &bytes).map_err(|e| format!("写入文件失败: {}", e))?;

    // Open the dmg file
    Command::new("open")
        .arg(&dmg_path)
        .spawn()
        .map_err(|e| format!("打开安装包失败: {}", e))?;

    Ok(())
}
