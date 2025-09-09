
\restrict Dh0FRGtTcThrbLDcCGdAyK1JudwZoH2fKbfOmVlWguuy2j4A4rYgH5oVsG2Tuwk

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict Dh0FRGtTcThrbLDcCGdAyK1JudwZoH2fKbfOmVlWguuy2j4A4rYgH5oVsG2Tuwk

RESET ALL;
