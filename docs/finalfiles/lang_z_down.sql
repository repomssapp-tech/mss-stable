-- Rollback of 20261005120000_content_table.sql. Drops ONLY objects that migration created.
-- WARNING: deletes all rows of catalog.content (including any translations added after the migration).
drop table if exists catalog.content cascade;
drop table if exists catalog.language cascade;
drop function if exists catalog.content_checksum(text,text,text,text,text,text,text,text);
drop function if exists catalog.jsonb_text_array(jsonb);
drop function if exists catalog._nz(text);
