-- Rollback of 20261005120000_content_language_tables.sql. Drops ONLY objects that migration created.
-- WARNING: also drops any content_<lang> table created later by add_language() and any translations in them.
drop function if exists catalog.add_language(text, text);
drop table if exists catalog.content_hi, catalog.content_ta, catalog.content_en, catalog.language cascade;
drop function if exists catalog.content_checksum(text,text,text,text,text,text,text,text);
drop function if exists catalog.jsonb_text_array(jsonb);
drop function if exists catalog._nz(text);
