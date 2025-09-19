
\restrict J61Up6K27S46tveONQg5xOFY12sfyfic7SITnnqXuHA0l4ogAOIEBxuE9cI5tWB

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict J61Up6K27S46tveONQg5xOFY12sfyfic7SITnnqXuHA0l4ogAOIEBxuE9cI5tWB

RESET ALL;
