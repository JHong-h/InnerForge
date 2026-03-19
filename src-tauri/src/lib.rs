mod db;
mod models;
mod commands;

use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_store::Builder::default().build())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_notification::init())
        .setup(|app| {
            let app_data = app.path().app_data_dir().expect("failed to get app data dir");
            std::fs::create_dir_all(&app_data).ok();
            let db_path = app_data.join("innerforge.db");
            let conn = db::initialize(&db_path)?;
            app.manage(db::DbState(std::sync::Mutex::new(conn)));

            // Create attachments directory
            let attachments_dir = app_data.join("attachments");
            std::fs::create_dir_all(&attachments_dir).ok();

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::periods::get_periods,
            commands::periods::create_period,
            commands::periods::update_period_status,
            commands::periods::delete_period,
            commands::entries::get_entries,
            commands::entries::create_entry,
            commands::entries::update_entry,
            commands::entries::delete_entry,
            commands::entries::add_attachment,
            commands::ai_config::get_ai_configs,
            commands::ai_config::create_ai_config,
            commands::ai_config::update_ai_config,
            commands::ai_config::delete_ai_config,
            commands::ai_config::test_ai_connection,
            commands::reports::get_reports,
            commands::reports::delete_report,
            commands::ai_service::run_daily_insight,
            commands::ai_service::run_period_summary,
            commands::ai_service::run_restructure_plan,
            commands::skills::get_skill_records,
            commands::export::export_report,
            commands::export::export_all,
            commands::reminder::check_should_remind,
            commands::updater::check_for_update,
            commands::updater::download_and_install_update,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
