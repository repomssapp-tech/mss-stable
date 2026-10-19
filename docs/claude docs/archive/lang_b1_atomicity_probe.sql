create table catalog._atomicity_probe (i int);
do $$ begin raise exception 'PROBE: expected failure'; end $$;
