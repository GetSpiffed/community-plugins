WHENEVER SQLERROR EXIT SQL.SQLCODE

delete from person where id in (1,2,3);
commit;
exit;
