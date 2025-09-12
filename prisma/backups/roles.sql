
\restrict kgiHA3D3dAzlaUcs9KgkJ1Nap1NDqxXdpzCUp33hK18cPRxDcL0l6znQfA1wL94

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

\unrestrict kgiHA3D3dAzlaUcs9KgkJ1Nap1NDqxXdpzCUp33hK18cPRxDcL0l6znQfA1wL94

RESET ALL;
