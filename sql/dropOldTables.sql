DROP TABLE IF EXISTS "label" CASCADE;
DROP TABLE IF EXISTS "group", "group_type" CASCADE;
DROP TABLE IF EXISTS "user_group" CASCADE;
DROP TABLE IF EXISTS "menu", "menu_profile" CASCADE;
DROP TABLE IF EXISTS "permission_seebase", "platform" CASCADE;
DROP TABLE IF EXISTS "time_to_release_standard" CASCADE;
DROP TABLE IF EXISTS "towed_to_base_standard" CASCADE;
DROP TABLE IF EXISTS "profile_notification" CASCADE;
DROP TABLE IF EXISTS "profile_andon_notification" CASCADE;
ALTER TABLE "time_to_release_standard2" RENAME TO "time_to_release_standard";
ALTER TABLE "towed_to_base_standard2" RENAME TO "towed_to_base_standard";

