--
-- PostgreSQL database dump
--

\restrict 7KtPhTTh4uQBIIfLxiS92iFa05uHHQmLqw7nwgiTrO8E5e9DCm5baTteUe9Ued7

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.user_stocks DROP CONSTRAINT IF EXISTS user_stocks_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_stocks DROP CONSTRAINT IF EXISTS user_stocks_symbol_fkey;
ALTER TABLE IF EXISTS ONLY public.quotes DROP CONSTRAINT IF EXISTS quotes_symbol_fkey;
DROP INDEX IF EXISTS public.ix_stocks_symbol_trgm;
DROP INDEX IF EXISTS public.ix_stocks_name_trgm;
DROP INDEX IF EXISTS public.ix_quotes_symbol_interval_ts;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.user_stocks DROP CONSTRAINT IF EXISTS user_stocks_pkey;
ALTER TABLE IF EXISTS ONLY public.stocks DROP CONSTRAINT IF EXISTS stocks_pkey;
ALTER TABLE IF EXISTS ONLY public.quotes DROP CONSTRAINT IF EXISTS quotes_pkey;
ALTER TABLE IF EXISTS ONLY public.alembic_version DROP CONSTRAINT IF EXISTS alembic_version_pkc;
ALTER TABLE IF EXISTS public.users ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.users_id_seq;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_stocks;
DROP TABLE IF EXISTS public.stocks;
DROP TABLE IF EXISTS public.quotes;
DROP TABLE IF EXISTS public.alembic_version;
DROP EXTENSION IF EXISTS pg_trgm;
--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotes (
    symbol character varying(12) NOT NULL,
    "interval" character varying(8) NOT NULL,
    ts timestamp with time zone NOT NULL,
    open numeric(18,6) NOT NULL,
    high numeric(18,6) NOT NULL,
    low numeric(18,6) NOT NULL,
    close numeric(18,6) NOT NULL,
    volume bigint,
    CONSTRAINT ck_quotes_interval CHECK ((("interval")::text = ANY ((ARRAY['1min'::character varying, '5min'::character varying, '15min'::character varying])::text[])))
);


--
-- Name: stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks (
    symbol character varying(12) NOT NULL,
    name character varying(255) NOT NULL,
    currency character varying(8) NOT NULL,
    exchange character varying(32) NOT NULL,
    mic_code character varying(8) NOT NULL,
    country character varying(64) NOT NULL,
    type character varying(64) NOT NULL,
    last_seen_at timestamp with time zone NOT NULL,
    delisted_at timestamp with time zone
);


--
-- Name: user_stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_stocks (
    user_id integer NOT NULL,
    symbol character varying(12) NOT NULL,
    added_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    full_name character varying(120) NOT NULL,
    password_hash character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alembic_version (version_num) FROM stdin;
529bd7f366dd
\.


--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.quotes (symbol, "interval", ts, open, high, low, close, volume) FROM stdin;
\.


--
-- Data for Name: stocks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stocks (symbol, name, currency, exchange, mic_code, country, type, last_seen_at, delisted_at) FROM stdin;
A	Agilent Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AA	Alcoa Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAC	Ares Acquisition Corp. III Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AACT	Kodiak AI Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAC.UN	Ares Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAC.WT	Ares Acquisition Corporation Re	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AADX	Applied Aerospace & Defense, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAMI	Acadian Asset Management Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAP	Advance Auto Parts Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAQC	Accelerate Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AAQC.UN	Accelerate Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
AAT	American Assets Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AAUC	Allied Gold Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AB	AllianceBernstein Holding L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
ABBV	AbbVie Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABCB	Ameris Bancorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABEV	Ambev S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ABG	Asbury Automotive Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABM	ABM Industries Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABR	Arbor Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ABR-D	Arbor Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ABR-E	Arbor Realty Trust 6.25% Series	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ABR.PR.D	Arbor Realty Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ABR.PR.E	Arbor Realty Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ABR.PR.F	Arbor Realty Trust 6.25% Series	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ABT	Abbott Laboratories	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABX	Abacus Global Management, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ABXL	Abacus Global Management, Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
ACA	Arcosa, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACCO	Acco Brands Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACCS	ACCESS Newswire Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACEL	Accel Entertainment Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACH	Accendra Health Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACHR	Archer Aviation Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACI	Albertsons Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACM	AECOM	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACN	Accenture PLC Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACP.PR.A	Aberdeen Income Credit Strategies Fund	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ACR	ACRES Commercial Realty Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ACR-C	ACRES Commercial Realty Corp. 8	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ACR-D	ACRES Commercial Realty Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ACRE	Ares Commercial Real Estate Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ACR.PR.C	ACRES Commercial Realty Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ACR.PR.D	ACRES Commercial Realty Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ACU	Acme United Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ACVA	ACV Auctions Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AD	Array Digital Infrastructure, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ADC	Agree Realty Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ADC.PR.A	Agree Realty Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ADCT	ADC Therapeutics SA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ADIG	ADI Global Distribution Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ADM	Archer-Daniels-Midland Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ADNT	Adient plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ADRA.UN	Adara Acquisition Corp.	USD	NYSE	XASE	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ADT	ADT Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AEE	Ameren Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AEFC	Aegon Funding Company LLC 5.1% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AEG	Aegon Ltd. New York Registry Shares	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AEM	Agnico Eagle Mines Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AEO	American Eagle Outfitters Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AEON	Aeon Biopharma, Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AER	AerCap Holdings N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AES	The AES Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AESI	Atlas Energy Solutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALH	Alliance Laundry Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AEXA	American Exceptionalism Acquisition Corp. A Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AFG	American Financial Group Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AFGB	American Financial Group Preferred Stock 5.875% Series	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AFGC	American Financial Group Preferred Stock 5.125% Due 12/15/2059	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AFGD	American Financial Group 5.625% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AFGE	American Financial Group Preferred Stock 4.5%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AFI	Armstrong Flooring Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AFL	Aflac Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AG	First Majestic Silver Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGBK	AGI Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGCO	AGCO Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGI	Alamos Gold Inc. Class A Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGIG	Abundia Global Impact Group Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGL	agilon health, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGM	Federal Agricultural Mortgage Corp. Class C Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGM.A	Federal Agricultural Mortgage Corporation Class A Voting Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGM-E	Federal Agricultural Mortgage Corp. Class C Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGM-F	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM-G	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM-H	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM-I	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM.PR.D	Federal Agricultural Mortgage Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM.PR.E	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM.PR.F	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGM.PR.G	Federal Agricultural Mortgage Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGO	Assured Guaranty Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGO.PR.E	Assured Guaranty Municipal Holdings Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AGRO	Adecoagro S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AGX	Argan Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AHH	AH Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AHH.PR.A	Armada Hoffler Properties Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHL.PR.D	Aspen Insurance Holdings Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHL.PR.E	Aspen Insurance Holdings Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHL.PR.F	Aspen Insurance Holdings Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AHR	American Healthcare REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AHRT-A	AH Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AHT	Ashford Hospitality Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AHT.PR.D	Ashford Hospitality Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHT.PR.F	Ashford Hospitality Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHT.PR.G	Ashford Hospitality Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHT.PR.H	Ashford Hospitality Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AHT.PR.I	Ashford Hospitality Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AI	C3.ai, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIG	American International Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AII	American Integrity Insurance Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIIA	AI Infrastructure Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIIA.UN	AI Infrastructure Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIM	AIM ImmunoTech Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIN	Albany International Corp. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIR	AAR Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIRI	Air Industries Group	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIT	Applied Industrial Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIV	Apartment Investment and Management Co. Class A	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AIZ	Assurant Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AIZN	Assurant Inc. Preferred Stock 5.25%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AJG	Arthur J. Gallagher & Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AKA	a.k.a. Brands Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AKO.A	Embotelladora Andina, S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AKO.B	Embotelladora Andina S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AKR	Acadia Realty Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ALB	Albemarle Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALB.PR.A	Albemarle Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALC	Alcon Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALG	Alamo Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALIN.PR.B	Altera Infrastructure L.P. 8.50	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALIN.PR.E	Altera Infrastructure L.P. 8.87	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALIT	Alight Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALK	Alaska Air Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALL	The Allstate Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALLE	Allegion plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALL-J	Allstate Corporation (The) Depositary Shares each representing a 1/1,000th interest in a share of Fixed Rate Noncumulative Perpetual Preferred Stock, Series J	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALL.PR.B	Allstate Corp-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALL.PR.H	Allstate Corp-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALL.PR.I	Allstate Corp-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALLY	Ally Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALSN	Allison Transmission Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALTG	Alta Equipment Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALTG.PR.A	Alta Equipment Group Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ALUB	Alussa Energy Acquisition Corp. II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALUB.UN	ALUB.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALV	Autoliv Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ALX	Alexander's Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AM	Antero Midstream Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMBC	Ambac Financial Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMBO	Ambow Education Holding Ltd. ADR	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AMBP	Ardagh Metal Packaging S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMBQ	Ambiq Micro, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMC	AMC Entertainment Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMCR	Amcor plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AME	AMETEK, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMG	Affiliated Managers Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMH	American Homes 4 Rent Class A	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AMH.PR.G	American Homes 4 Rent	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AMH.PR.H	American Homes 4 Rent	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AMN	AMN Healthcare Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMP	Ameriprise Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMPE	Ampio Pharmaceuticals Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMPI.UN	Advanced Merger Partners, Inc.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
AMPX	Amprius Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMPY	Amplify Energy Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMR	Alpha Metallurgical Resources, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMRC	Ameresco Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMRZ	Amrize Ltd	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMS	American Shared Hospital Services	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMT	American Tower Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AMTB	Amerant Bancorp Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMTD	AMTD IDEA Group American Depositary Shares, each representing six Class A ordinary shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AMTM	Amentum Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMWL	American Well Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AMX	America Movil SAB de CV ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AMZE	Amaze Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AN	AutoNation, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANAC.WT	Arctos NorthStar Acquisition Co	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANDG	Andersen Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANET	Arista Networks Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANF	Abercrombie & Fitch Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANG.PR.D	American National Group Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANGX	Angel Studios, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANRO	Alto Neuroscience Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ANVS	Annovis Bio, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AOMD	Angel Oak Mortgage REIT Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AOMN	Angel Oak Mortgage REIT Preferred 9.5% 07/30/29	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AOMR	Angel Oak Mortgage REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AON	Aon plc Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AORT	Artivion Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AOS	A. O. Smith Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AP	Ampco-Pittsburgh Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APAM	Artisan Partners Asset Management Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APC	Arko Petroleum Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APD	Air Products and Chemicals Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APG	APi Group Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APH	Amphenol Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APLE	Apple Hospitality REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
APN	Apeiron Capital Investment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APO	Apollo Global Management Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APOS	Apollo Global Management, Inc. 7.625% Fixed-Rate Resettable Junior Subordinated Notes due 2053	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
APSG.UN	Apollo Strategic Growth Capital	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
APT	Alpha Pro Tech, Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APTV	Aptiv PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
APUS	Apimeds Pharmaceuticals US Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AQN	Algonquin Power & Utilities Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AQNB	Algonquin Power & Utilities Corp. Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AR	Antero Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARCO	Arcos Dorados Holdings Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARD	Ardagh Group SA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARDT	Ardent Health, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARE	Alexandria Real Estate Equities, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AREN	The Arena Group Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARES	Ares Management Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARES-B	Ares Management Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARI	Apollo Commercial Real Estate Finance, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ARIS	Aris Mining Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARL	American Realty Investors Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARLO	Arlo Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARMK	Aramark	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARMP	Armata Pharmaceuticals, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AROC	Archrock Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARR	ARMOUR Residential REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ARR.PR.C	ARMOUR Residential REIT Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ARW	Arrow Electronics Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ARX	Accelerant Holdings Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AS	Amer Sports, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASAI	Sendas Distribuidora S.A.	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ASAN	Asana Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASAQ.UN	Atlantic Avenue Acquisition Corp	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ASB	Associated Banc-Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASBA	Associated Banc-Corp Preferred Stock 6.625% Callable 03/01/2033	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ASB.PR.E	Associated Banc-Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ASB.PR.F	Associated Banc-Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ASC	Ardmore Shipping Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASGN	Everforth Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASH	Ashland Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASIC	Ategrity Specialty Insurance Company Holdings	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASIX	AdvanSix Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASM	Avino Silver & Gold Mines Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASPN	Aspen Aerogels, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ASR	Grupo Aeroportuario del Sureste S.A.B. de C.V. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ASX	ASE Technology Holding Co., Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ASZ.UN	Austerlitz Acquisition Corporation II	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ATA.UN	Americas Technology Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ATCH	AtlasClear Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATEK.UN	Athena Technology Acquisition Corp. II	USD	NYSE	XASE	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ATEN	A10 Networks, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATEST	ATEST	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATH-E	Athene Holding Ltd. Depositary 	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ATHHF	Aether Catalyst Solutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATHM	Autohome Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ATH.PR.A	Athene Holding Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ATH.PR.B	Athene Holding Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ATH.PR.D	Athene Holding Ltd.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ATH.PR.E	Athene Holding Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATHS	Athene Holding Ltd. Preferred Stock 7.25%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ATI	ATI Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATKR	Atkore Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATMR	Altimar Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATMR.UN	Altimar Acquisition Corp. II	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ATMU	Atmus Filtration Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATNM	Actinium Pharmaceuticals, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATO	Atmos Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATR	AptarGroup Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATS	ATS Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ATTO	Attovia Therapeutics Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AU	AngloGold Ashanti plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AUB	Atlantic Union Bankshares Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AUB.PR.A	Atlantic Union Bankshares Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AUNA	Auna S.A. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AUST	Austin Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AUXX	Gold X2 Mining Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVA	Avista Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVAL	Grupo Aval Acciones y Valores S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AVAN	Avanti Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVAN.UN	Avanti Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
AVB	AvalonBay Communities, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
AVBC	Avidia Bancorp Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVD	American Vanguard Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVEX	AEVEX Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVK.RI	Advent Convertible and Income F	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVNT	Avient Corp. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVTR	Avantor, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVX	Avax One Technology Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AVY	Avery Dennison Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AWI	Armstrong World Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AWK	American Water Works Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AWR	American States Water Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AWX	Avalon Holdings Corp. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AX	Axos Financial, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AXIL	AXIL Brands, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AXP	American Express Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AXR	AMREP Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AXS	Axis Capital Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AXS.PR.E	Axis Capital Holdings Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
AXTA	Axalta Coating Systems Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AYI	Acuity Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AZO	AutoZone, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AZTR	Azitra Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AZUL	Azul S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
AZZ	AZZ Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
B	Barrick Mining Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BA	Boeing Co/The	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BA-A	Boeing Co/The	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BABA	Alibaba Group Holding Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BAC	Bank of America Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BACA.UN	Berenson Acquisition Corp. I	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
BAC.PR.B	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.E	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.K	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.L	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.M	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.N	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.O	Bank of America Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.P	Bank of America Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.Q	Bank of America Corporation Dep	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BAC.PR.S	Bank of America Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAH	Booz Allen Hamilton Holding Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAK	Braskem S.A. Sponsored ADR Class A	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BALL	Ball Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BALY	Bally's Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAM	Brookfield Asset Management Ltd. Class A Limited Voting Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAMR	Brookfield Asset Management Reinsurance Partners Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BANC	Banc of California, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BANC-F	Banc of California, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAP	Credicorp Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BARK	BARK Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BATL	Battalion Oil Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BAX	Baxter International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BB	BlackBerry Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBAI	BigBear.ai Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBAR	Banco BBVA Argentina S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BBD	Banco Bradesco S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BBDC	Barings BDC Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBDO	Banco Bradesco S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BBT	Beacon Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBUC	Brookfield Business Corporation Class A Subordinate Voting Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBVA	Banco Bilbao Vizcaya Argentaria, S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BBW	Build-A-Bear Workshop Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBWI	Bath & Body Works Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BBY	Best Buy Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BC	Brunswick Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCC	Boise Cascade Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCE	BCE Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCH	Banco de Chile ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BCHT	Birchtech Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCO	The Brink's Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BC.PR.C	Brunswick Corp-DE	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BCS	Barclays PLC Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BCSF	Bain Capital Specialty Finance, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCSS	Bain Capital GSS Investment Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCSS.UN	BCSS.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCSS.WT	Bain Capital GSS Investment Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BCV.PR.A	Bancroft Fund Ltd	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BDC	Belden Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BDL	Flanigan's Enterprises, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BDN	Brandywine Realty Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BDR	Blonder Tongue Laboratories Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BDX	Becton, Dickinson and Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BE	Bloom Energy Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BEBE.UN	TGE Value Creative Solutions Co	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BEKE	KE Holdings Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BEN	Franklin Templeton Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BEP	Brookfield Renewable Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
BEP-A	Brookfield Renewable Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
BEPC	Brookfield Renewable Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BEPH	Brookfield BRP Holdings Inc. 4.625% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BEPI	Brookfield BRP Holdings Inc. Preferred Stock 4.875% Perpetual	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BEPJ	Brookfield BRP Holdings 7.25% Perpetual Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BEP.PR.A	Brookfield Renewable Partners L.P.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BESS	Bimergen Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BESS.WT	BESS.WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BETA	BETA Technologies Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BF.A	Brown-Forman Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BFAM	Bright Horizons Family Solutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BF.B	Brown-Forman Corp. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BFH	Bread Financial Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BFH-A	Bread Financial Holdings, Inc.	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BFH-B	Bread Financial Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BFLY	Butterfly Network Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BFS	Saul Centers, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BFS.PR.D	Saul Centers Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BFS.PR.E	Saul Centers Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BG	Bunge Global SA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BGI	Birks Group Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BGS	B&G Foods, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BGSF	BGSF Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BGSI	Boyd Group Services Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BH	Biglari Holdings Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BH.A	Biglari Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BHB	Bar Harbor Bankshares, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RXO	RXO Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BHC	Bausch Health Companies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BHE	Benchmark Electronics Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BHM	Bluerock Homes Trust, Inc.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BHP	BHP Group Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BHR	Braemar Hotels & Resorts Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BHR.PR.B	Braemar Hotels & Resorts Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BHR.PR.D	Braemar Hotels & Resorts Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BHVN	Biohaven Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BID	Tribeca Strategic Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIII	Black Spade Acquisition III Co. Cl A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIII.UN	Black Spade Acquisition III Co	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BILL	BILL Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIO	Bio-Rad Laboratories Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIO.B	Bio-Rad Laboratories, Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIP	Brookfield Infrastructure Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
BIP-A	Brookfield Infrastructure Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
BIP-B	Brookfield Infrastructure Partners L.P.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BIPC	Brookfield Infrastructure Corporation Class A Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BIPH	Brookfield Infrastructure Finance ULC Preferred Stock 5% 2081	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BIPI	Brookfield Infrastructure Partners L.P. Preferred Stock 5.125% Perpetual	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BIPJ	Brookfield Infrastructure Partners ULC Preferred Stock 7.25%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BIRK	Birkenstock Holding plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BJ	BJ's Wholesale Club Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BK	The Bank of New York Mellon Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKD	Brookdale Senior Living Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKE	The Buckle, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKH	Black Hills Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKKT	Bakkt Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKSY	BlackSky Technology Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKTI	BK Technologies Corporation Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKU	BankUnited Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BKV	BKV Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLCO	Bausch + Lomb Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLDR	Builders FirstSource Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLK	BlackRock Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLND	Blend Labs, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLSH	Bullish Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BLX	Bladex Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BMA	Banco Macro S.A. ADR Class B	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BMI	Badger Meter, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BML.PR.G	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BML.PR.H	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BML.PR.J	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BML.PR.L	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BMNP	BitMine Immersion Technologies, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BMNR	BitMine Immersion Technologies, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BMO	Bank of Montreal	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BMY	Bristol-Myers Squibb Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BN	Brookfield Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BNED	Barnes & Noble Education Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BNH	Brookfield Finance Inc. Preferred Stock 4.625%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BNJ	Brookfield Finance I UK PLC Preferred Stock, 4.5% Perpetual	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BNL	Broadstone Net Lease, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BNS	Bank of Nova Scotia	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BNT	Brookfield Wealth Solutions Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BNY	Bank of New York Mellon Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BNY-K	The Bank Of New York Mellon Corporation	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BOBS	Bob's Discount Furniture, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOC	Boston Omaha Corp Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BODI	The Beachbody Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOH	Bank of Hawaii Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOH-B	Bank of Hawaii Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOH.PR.A	Bank of Hawaii Corporation Depo	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BOOT	Boot Barn Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BORR	Borr Drilling Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOW	Bowhead Specialty Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOWL	Lucky Strike Entertainment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BOX	Box Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BP	BP Plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BQ	Boqii Holding Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BR	Broadridge Financial Solutions, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRBR	BellRing Brands Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRBS	Blue Ridge Bankshares Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRC	Brady Corporation Class A Nonvoting Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRCC	BRC Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRIA	BrilliA Inc. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRK.A	Berkshire Hathaway Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRK.B	Berkshire Hathaway Inc. Class B	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRN	Barnwell Industries Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRO	Brown & Brown Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BROS	Dutch Bros Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRSL	Brightstar Lottery PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BRSP	BrightSpire Capital Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BRT	BRT Apartments Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BRX	Brixmor Property Group Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BSAC	Banco Santander Chile SA ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BSBR	Banco Santander (Brasil) S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BSM	Black Stone Minerals, L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
BSX	Boston Scientific Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTE	Baytex Energy Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTG	B2Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTGO	BitGo Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTI	British American Tobacco plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BTN	Ballantyne Strong Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTTR	SRx Health Solutions Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BTU	Peabody Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BUD	Anheuser-Busch InBev SA/NV Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BUDA	Buda Juice Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BUR	Burford Capital Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BURL	Burlington Stores Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BURUD	NUBURU INC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BV	BrightView Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BVN	Compañía de Minas Buenaventura S.A.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
BW	Babcock & Wilcox Enterprises, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BW-A	Babcock & Wilcox Enterprises, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BWA	BorgWarner Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BWIV	Blue Water Acquisition Corp. IV Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BWIV.UN	Blue Water Acquisition Corp. IV	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BWLP	BW LPG Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BWMX	Betterware de México, S.A.P.I. de C.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BW.PR.A	Babcock & Wilcox Enterprises, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
BWXT	BWX Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BX	Blackstone Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BXC	BlueLinx Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BXDC	Blackstone Digital Infrastructure Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BXMT	Blackstone Mortgage Trust Inc Class A	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BXP	BXP, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
BXSL	Blackstone Secured Lending Fund	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BY	Byline Bancorp, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BYD	Boyd Gaming Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
BZH	Beazer Homes USA, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
C	Citigroup Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAAP	Corporación América Airports S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CABO	Cable One Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CACI	CACI International Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAE	CAE Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAG	Conagra Brands Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAH	Cardinal Health Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAI.PR.A	CAI International Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CAI.PR.B	CAI International Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CAL	Caleres, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CALX	Calix Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CANF	Can-Fite BioPharma Ltd. ADR	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CANG	Cango Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAP	Capitol Investment Corp. V	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAPL	CrossAmerica Partners LP Common Units	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
CARR	Carrier Global Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CARS	Cars.com Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAS.UN	Cascade Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CAT	Caterpillar Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CATO	The Cato Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CATX	Perspective Therapeutics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CAVA	Cava Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CB	Chubb Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBAN	Colony Bankcorp, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBB.PR.B	Cincinnati Bell Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CBL	CBL & Associates Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CBNA	Chain Bridge Bancorp Inc Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBRE	CBRE Group Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBT	Cabot Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBU	Community Financial System, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CBZ	CBIZ, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CC	The Chemours Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCAC.UN	CITIC Capital Acquisition Corp	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CCC	CCC Intelligent Solutions Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCEL	Cryo-Cell International, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCI	Crown Castle Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CCID	Carlyle Credit Income Fund	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CCJ	Cameco Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCK	Crown Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCL	Carnival Corporation Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCM	Concord Medical Services Holdings Limited ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CCO	Clear Channel Outdoor Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCS	Century Communities, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CCU	Compañía Cervecerías Unidas S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CCZ	COMCAST 2.0% EX SB 101529"ZONE	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CDE	Coeur Mining Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CDLR	Cadeler A/S Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CDP	COPT Defense Properties	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CDRE	Cadre Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CDR.PR.B	Cedar Realty Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CDR.PR.C	Cedar Realty Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CE	Celanese Corp. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CEIN	Camber Energy Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CELG.RI	Bristol-Myers Squibb Company Ce	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CELP	Cypress Energy Partners LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
CEPU	Central Puerto S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CF	CF Industries Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CFG	Citizens Financial Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CFG-H	Citizens Financial Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CFG-I	Citizens Financial Group, Inc.	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CFG.PR.E	Citizens Financial Group Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CFR	Cullen/Frost Bankers, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CFR.PR.B	Cullen/Frost Bankers, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CFTR-A	Cantor Fitzgerald Income Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CFX	Enovis Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CFXA	Colfax Corp	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CGA	China Green Agriculture, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CGAU	Centerra Gold Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHAI	Core AI Holdings, Inc.	USD	NYSE	ARCX	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHCT	Community Healthcare Trust Incorporated	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CHD	Church & Dwight Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHE	Chemed Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHGG	Chegg Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHH	Choice Hotels International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHMI	Cherry Hill Mortgage Investment Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CHMI.PR.A	Cherry Hill Mortgage Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CHMI.PR.B	Cherry Hill Mortgage Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CHOW	ChowChow Cloud International Holdings Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHPT	ChargePoint Holdings, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CHT	Chunghwa Telecom Co., Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CHWY	Chewy Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CI	The Cigna Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CIA	Citizens, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CIB	Grupo Cibest S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CICB	CION Investment Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIEN	Ciena Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CIG	Companhia Energética de Minas Gerais S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CIG.C	Companhia Energética de Minas Gerais	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CIM	Chimera Investment Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CIMN	Chimera Investment Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIMO	Chimera Investment Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIMP	Chimera Investment Corporation 8.875% Senior Notes due 2030	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIM.PR.A	Chimera Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIM.PR.B	Chimera Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIM.PR.C	Chimera Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CIM.PR.D	Chimera Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CINT	CI&T Inc. Class A Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CION	CION Investment Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CITR	CitroTech Inc. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CIX	CompX International Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CKX	CKX Lands Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CL	Colgate-Palmolive Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLAA.UN	Colonnade Acquisition Corp. II	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CLB	Core Laboratories Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLBR	Colombier Acquisition Corp. III Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLBR.UN	Colombier Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CLDI	Calidi Biotherapeutics, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLDT	Chatham Lodging Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CLDT-A	Chatham Lodging Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CLDT.PR.A	Chatham Lodging Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CLF	Cleveland-Cliffs Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLH	Clean Harbors, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLNC	Colony Credit Real Estate Inc	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CLPR	Clipper Realty Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CLS	Celestica Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLVT	Clarivate Plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLW	Clearwater Paper Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CLX	The Clorox Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CM	Canadian Imperial Bank of Commerce	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMBT	Cmb.Tech NV	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMC	Commercial Metals Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMCL	Caledonia Mining Corporation Plc Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMCM	Cheetah Mobile Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CMDB	Costamare Bulkers Holdings Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMG	Chipotle Mexican Grill, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMI	Cummins Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMP	Compass Minerals International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMRE	Costamare Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMRE.PR.B	Costamare Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMRE.PR.C	Costamare Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMRE.PR.D	Costamare Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMS	CMS Energy Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMSA	CMS Energy Corp. Preferred Stock 5.625% 03/15/2078	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMSC	CMS Energy Corp. Preferred Stock 5.875% 2078	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMSD	CMS Energy Corp. 5.875% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMS.PR.B	Consumers Energy Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMS.PR.C	CMS Energy Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CMT	Core Molding Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CMTG	Claros Mortgage Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CNA	CNA Financial Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNC	Centene Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CND.UN	Concord Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CNF	CNFinance Holdings Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CNH	CNH Industrial N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNHI	CNH Industrial N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNI	Canadian National Railway Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNK	Cinemark Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNL	Collective Mining Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNM	Core & Main Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNMD	CONMED Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNNE	Cannae Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNO	CNO Financial Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNO.PR.A	CNO Financial Group, Inc. 5.125	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CNP	CenterPoint Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNQ	Canadian Natural Resources Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNR	Core Natural Resources Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNS	Cohen & Steers Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CNX	CNX Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CODI	Compass Diversified Holdings	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CODI.PR.A	Compass Diversified Holdings	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CODI.PR.B	Compass Diversified Holdings	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CODI.PR.C	Compass Diversified Holdings	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COE	51Talk Online Education Group ADR	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
COF	Capital One Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COF.PR.I	Capital One Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COF.PR.J	Capital One Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COF.PR.K	Capital One Financial Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COF.PR.L	Capital One Financial Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COF.PR.N	Capital One Financial Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
COHN	Cohen & Company Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COHR	Coherent Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COLD	Americold Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
COMP	Compass Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CON	Concentra Group Holdings Parent, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COOK	Traeger Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COP	ConocoPhillips	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COPL	Copley Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COPL.UN	Copley Acquisition Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COPL.WT	Copley Acquisition Corp WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COPR	Idaho Copper Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COPR.WT	COPR.WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COR	Cencora Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COSO	CoastalSouth Bancshares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COTY	Coty Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
COUR	Coursera, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CP	Canadian Pacific Kansas City Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPA	Copa Holdings, S.A. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPAC	Cementos Pacasmayo S.A.A. American Depositary Shares (Each representing five Common Shares)	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CPAY	Corpay Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPF	Central Pacific Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPHI	China Pharma Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPK	Chesapeake Utilities Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPNG	Coupang, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPRI	Capri Holdings Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
C.PR.N	Citigroup Capital XIII	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CPS	Cooper-Standard Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CPSR.UN	Capstar Special Purpose Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CPT	Camden Property Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CQP	Cheniere Energy Partners, L.P. Common Units Representing Limited Partner Interests	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
C-R	Citigroup Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CR	Crane Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRBD	Corebridge Financial Inc. Preferred Stock 6.375%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CRBG	Corebridge Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRC	California Resources Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRCL	Circle Internet Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRD.A	Crawford & Company Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRD.B	Crawford & Company Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRGY	Crescent Energy Company Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRH	CRH plc Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRI	Carter's Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRK	Comstock Resources, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRL	Charles River Laboratories International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRM	Salesforce, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRS	Carpenter Technology Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CRT	Cross Timbers Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
CRU.UN	Crucible Acquisition Corporation	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
CSAN	Cosan S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CSL	Carlisle Companies Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSLT	Castlight Health Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSPR	Casper Sleep Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSQR	Csquare Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSR	Centerspace	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CSR.PR.C	Centerspace	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CSTM	Constellium SE Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSV	Carriage Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CSW	CSW Industrials Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTAA	ClearThink 1 Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTA.PR.A	EI du Pont de Nemours & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CTA.PR.B	EI du Pont de Nemours & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CTEV	Claritev Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTGG	Qwest Corporation 6.50% Notes due 2051	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CTGO	Contango Silver & Gold Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTHH	Qwest Corporation	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
CTM	Castellum Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTO	CTO Realty Growth, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CTO-A	CTO Realty Growth, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CTO.PR.A	CTO Realty Growth, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CTOS	Custom Truck One Source Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTRE	CareTrust REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CTRI	Centuri Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTS	CTS Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CTVA	Corteva Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CUBB	Customers Bancorp Inc. 5.375% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
CUBE	CubeSmart	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CUBI	Customers Bancorp Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CULP	Culp, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CURB	Curbline Properties Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CURV	Torrid Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CUZ	Cousins Properties Incorporated	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
CVE	Cenovus Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVEO	Civeo Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVI	CVR Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVLG	Covenant Logistics Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVM	CEL-SCI Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVNA	Carvana Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVR	Chicago Rivet & Machine Co. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVS	CVS Health Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVSA	Covista Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVU	CPI Aerostructures, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CVX	Chevron Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CW	Curtiss-Wright Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CWEN	Clearway Energy Inc. Class C Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CWH	Camping World Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CWK	Cushman & Wakefield Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CWT	California Water Service Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CX	Cemex S.A.B. de C.V. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
CXM	Sprinklr Inc Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CXT	Crane NXT, Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CXW	CoreCivic, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CYBN	Cybin Inc. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CYD	China Yuchai International Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
CYH	Community Health Systems, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
D	Dominion Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DAC	Danaos Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DAL	Delta Air Lines, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DAN	Dana Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DAO	Youdao Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DAR	Darling Ingredients Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DAVA	Endava plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DB	Deutsche Bank AG	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DBD	Diebold Nixdorf, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DBI	Designer Brands Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DBRG	DigitalBridge Group Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DBRG.PR.H	DigitalBridge Group, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DBRG.PR.I	DigitalBridge Group, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DBRG.PR.J	DigitalBridge Group, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DC	Dakota Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DCBG	Dime Community Bancshares, Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
DCH	Dauch Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DCI	Donaldson Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DCO	Ducommun Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DCOM-	Dime Community Bancshares, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DD	DuPont de Nemours, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DDC	DDC Enterprise Limited Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DDD	3D Systems Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DDL	Dingdong (Cayman) Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DDS	Dillard's Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DDT	Dillards Capital Trust I 7.5% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DE	Deere & Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DEA	Easterly Government Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DEC	Diversified Energy Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DECK	Deckers Outdoor Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DEI	Douglas Emmett Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DELL	Dell Technologies Inc. Class C Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DEO	Diageo plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DFH	Dream Finders Homes Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DFIN	Donnelley Financial Solutions, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DFNS	T3 Defense Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DG	Dollar General Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DGAC	Disciplined Growth Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DGAC.UN	Disciplined Growth Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DGNR	Dragoneer Growth Opportunities Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DGX	Quest Diagnostics Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DHI	D.R. Horton, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DHR	Danaher Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DHR.PR.A	Danaher Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DHT	DHT Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DHX	DHI Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DIN	Dine Brands Global Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DINO	HF Sinclair Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DIS	The Walt Disney Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DIT	Amcon Distributing Co.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DK	Delek US Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DKL	Delek Logistics Partners, LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
DKS	DICK'S Sporting Goods, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DLB	Dolby Laboratories Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DLNG	Dynagas LNG Partners LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
DLNG.PR.A	Dynagas LNG Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DLR	Digital Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DLR.PR.J	Digital Realty Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DLR.PR.K	Digital Realty Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DLR.PR.L	Digital Realty Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DLX	Deluxe Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DMC	Del Monte Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DNA	Ginkgo Bioworks Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DNN	Denison Mines Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DNOW	DNOW Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DNZ.WT	D and Z Media Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOC	Healthpeak Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DOCN	DigitalOcean Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOCS	Doximity Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOLE	Dole plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOO	BRP Inc. Subordinate Voting Shares	USD	NYSE	ARCX	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOUG	Douglas Elliman Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOV	Dover Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DOW	Dow Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DPC	DPC Holdings PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DQ	Daqo New Energy Corp. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DRD	DRDGOLD Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DRH	DiamondRock Hospitality Company	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DRI	Darden Restaurants, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DRQ	Innovex International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DSS	DSS Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DSX	Diana Shipping Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DSX.PR.B	Diana Shipping Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DSX.WT	Diana Shipping Inc. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DT	Dynatrace Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DTB	DTE Energy Co. Preferred Stock 4.375% Due 10/15/2080	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DTC	Solo Brands, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DTE	DTE Energy Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DTG	DTE Energy Co. Preferred Stock 4.375%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DTK	DTE Energy Company 6.25% Junior Subordinated Debentures, Series H, due October 1, 2085	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DTM	DT Midstream, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DTW	DTE Energy Co. Preferred Stock 5.25% 12/01/2077	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DUK	Duke Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DUKB	Duke Energy Corp. Preferred 5.625%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DUK.PR.A	Duke Energy Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DUUKU	Duke Energy Corporation Depositary Shares, each representing a 1/1,000th interest in a share of 5.75% Series A Cumulative Redeemable Perpetual Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DV	DoubleVerify Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DVA	DaVita Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DVD	Dover Motorsports Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DVN	Devon Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DX	Dynex Capital Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DX-C	Dynex Capital Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
DXC	DXC Technology Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DXF	Eason Technology Ltd. American Depositary Shares (each representing sixty-thousand (60,000) Ordinary Shares)	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
DX.PR.C	Dynex Capital, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
DY	Dycom Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
DYNC	Dynamix Corporation Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
E	Eni S.p.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EAF	GrafTech International Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EAI	Entergy Arkansas LLC Preferred Stock 4.875%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EAT	Brinker International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EBF	Ennis Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EBR	Centrais Electricas Brasileiras S A	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EBS	Emergent BioSolutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EC	Ecopetrol S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ECCC	Eagle Point Credit Company Preferred Stock 6.5% 06/30/31	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ECC.PR.D	Eagle Point Credit Company Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ECCU	Eagle Point Credit Company Inc. Preferred Stock 7.75%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ECCV	Eagle Point Credit Company Inc. Preferred Stock 5.375%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ECF.PR.A	Ellsworth Growth and Income Fund Ltd	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ECG	Everus Construction Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ECL	Ecolab Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ECO	Okeanis Eco Tankers Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ECVT	Ecovyst Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ED	Consolidated Edison Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EDN	Edenor S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EDU	New Oriental Education & Technology Group Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EE	Excelerate Energy Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EFC	Ellington Financial Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
EFC.PR.B	Ellington Financial Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EFC.PR.C	Ellington Financial Inc. 8.625%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EFC.PR.D	Ellington Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EFOR	Everforth Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EFX	Equifax Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EFXT	Enerflex Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EG	Everest Group, Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EGG	Enigmatig Ltd. Ordinary Shares - Class A	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EGO	Eldorado Gold Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EGP	EastGroup Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
EGY	VAALCO Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EHC	Encompass Health Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EICA	Eagle Point Income Company Inc. 5% Notes due 2026	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EIG	Employers Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EIIA	Eagle Point Institutional Income Fund Preferred Stock 8.125%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EIX	Edison International	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EL	The Estée Lauder Companies Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELA	Envela Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELAN	Elanco Animal Health Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELC	Entergy Louisiana LLC Preferred Stock 4.875%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ELF	e.l.f. Beauty, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELIQQ	Electriq Power Holdings Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELLA	Ellington Credit Company 8.50% Notes due 2031	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ELLO	Ellomay Capital Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELMD	Electromed, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ELME	Elme Communities	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ELPC	Companhia Paranaense de Energia Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ELS	Equity LifeStyle Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ELV	Elevance Health, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EMA	Emera Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EMBJ	Embraer S.A. Sponsored American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EME	EMCOR Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EMN	Eastman Chemical Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EMP	Entergy Mississippi LLC Preferred	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EMR	Emerson Electric Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EMWP	Eros Media World PLC A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENB	Enbridge Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENCR	Ener-Core, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENFY	Enlightify Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENHA	Enhanced Group Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENIC	Enel Chile S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ENJ	Entergy New Orleans LLC Preferred Stock 5%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ENO	Entergy New Orleans LLC Preferred Stock 5.5%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ENOV	Enovis Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENPC	Executive Network Partnering Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENPC.UN	Executive Network Partnering Corporation	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
ENR	Energizer Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENR.PR.A	Energizer Holdings Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ENS	EnerSys	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ENVA	Enova International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EOG	EOG Resources, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EONR	EON Resources Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EONR.WT	EON Resources Inc WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EP	Empire Petroleum Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EPAC	Enerpac Tool Group Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EPAM	EPAM Systems, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EPC	Edgewell Personal Care Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EPD	Enterprise Products Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
EPM	Evolution Petroleum Corporation, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EP.PR.C	EL PASO ENR CP TSTI 4.75 TCPR	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EPR	EPR Properties	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
EPR.PR.C	EPR Properties	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EPR.PR.E	EPR Properties	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EPR.PR.G	EPR Properties	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EPRT	Essential Properties Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
EQBK	Equity Bancshares, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EQD.UN	Equity Distribution Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
EQH	Equitable Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EQHA.UN	EQ Health Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
EQH.PR.A	Equitable Holdings Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EQH.PR.C	Equitable Holdings, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
EQNR	Equinor ASA Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
EQR	Equity Residential	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EQS	Equus Total Return, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EQT	EQT Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EQX	Equinox Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ERJ	Embraer S.A. Sponsored ADR	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ERO	Ero Copper Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EROC	ERock, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EROK	EagleRock Land, LLC Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ES	Eversource Energy	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESAB	ESAB Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESBA	Empire State Realty OP, L.P. Series ES Operating Partnership Units	USD	NYSE	ARCX	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
ESE	Esco Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESI	Element Solutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESNT	Essent Group Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESP	Espey Mfg. & Electronics Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ESRT	Empire State Realty Trust, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ESS	Essex Property Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ESTC	Elastic N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ET	Energy Transfer LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
ETD	Ethan Allen Interiors Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ET-I	Energy Transfer LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
ETI.PR.	Entergy Texas Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ETN	Eaton Corporation plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ETR	Entergy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ETSS	Energy Transition Special Opportunities Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ETSS.UN	Energy Transition Special Oppor	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ETSS.WT	Energy Transition Special Opportunities WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EURN	Euronav NV	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVAC	EQV Ventures Acquisition Corp. II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVAC.UN	EQV Ventures Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVAC.WT	EQV Ventures Acquisition Corp II WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVC	Entravision Communications Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVEX	Eve Holding, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVH	Evolent Health Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVI	EVI Industries, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVMN	Evommune, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVR	Evercore Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVTC	Evertec Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EVTL	Vertical Aerospace Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EW	Edwards Lifesciences Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXK	Endeavour Silver Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXN	Excellon Resources Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXOD	Exodus Movement, Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXP	Eagle Materials Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXPD	Expeditors International of Washington Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
EXR	Extra Space Storage Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
F	Ford Motor Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FACA	Figure Acquisition Corp. I	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FACO	First Acceptance Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FAF	First American Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FBHS	Fortune Brands Home & Security Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FBIN	Fortune Brands Innovations, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FBK	FB Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FBP	First BanCorp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FBRT	Franklin BSP Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FBRT.PR.E	Franklin BSP Realty Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FC	Franklin Covey Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCAX.UN	Fortress Capital Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
FCBM	First Carolina Financial Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCF	First Commonwealth Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCN	FTI Consulting Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCPT	Four Corners Property Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FCRS	FutureCrest Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCRS.UN	FutureCrest Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCRS.WT	FutureCrest Acquisition Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FCX	Freeport-McMoRan Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FDS	FactSet Research Systems Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FDX	FedEx Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FDXF	FedEx Freight Holding Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FE	FirstEnergy Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FEDU	Four Seasons Education (Cayman) Inc. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FENG	Phoenix New Media Ltd. Sponsored ADR Class A	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FERG	Ferguson Enterprises Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FET	Forum Energy Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FF	FutureFuel Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FG	F&G Annuities & Life, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FGN	F&G Annuities & Life Inc. Preferred Stock 7.95%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FGSN	F&G Annuities & Life, Inc. 7.30% Perpetual Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FHI	Federated Hermes, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FHN	First Horizon Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FHN-H	First Horizon Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FHN.PR.E	First Horizon Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FHN.PR.F	First Horizon Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FHS	First High-School Education Group Co., Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FI	Fiserv Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FICO	Fair Isaac Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FIG	Figma Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FIGS	FIGS Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FIHL	Fidelis Insurance Holdings Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FINV	FinVolution Group Sponsored ADR Class A	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FIRY	Firy Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FIS	Fidelity National Information Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FISK	Empire State Realty OP, L.P. Series 250 Operating Partnership Units	USD	NYSE	ARCX	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
FITB-A	Fifth Third Bancorp	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FITB-I	Fifth Third Bancorp Depositary Share repstg 1/1000th Ownership Interest Perp Pfd Series I	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FITB-K	Fifth Third Bancorp	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FITB-M	Fifth Third Bancorp	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FIX	Comfort Systems USA, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FJET	Starfighters Space Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLG	Flagstar Bank, National Association	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLG-A	Flagstar Financial, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FLG-U	Flagstar Bank, National Association	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLNG	FLEX LNG Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLO	Flowers Foods, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLOC	Flowco Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLR	Fluor Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLS	Flowserve Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLT	Corpay Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLUT	Flutter Entertainment plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLYX	flyExclusive, Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FLYX.WT	flyExclusive, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FMAC	Future Money Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FMC	FMC Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FMS	Fresenius Medical Care AG - Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FMX	Fomento Economico Mexicano S.A.B. de C.V. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FN	Fabrinet	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FNB	F.N.B. Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FND	Floor & Decor Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FNF	Fidelity National Financial, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FNV	Franco-Nevada Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FOA	Finance of America Companies Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FOIL	Londian Wason New Energy Tech Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
FOR	Forestar Group Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FOUR	Shift4 Payments Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FOUR-A	Shift4 Payments Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FPAC.UN	Far Point Acquisition Corp	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
FPH	Five Point Holdings LLC Class A Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FPI	Farmland Partners Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
F.PR.B	Ford Motor Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
F.PR.C	Ford Motor Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
F.PR.D	Ford Motor Company 6.500% Notes	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FPS	Forgent Power Solutions Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FR	First Industrial Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FRC.PR.H	First Republic Bank-CA	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRC.PR.I	First Republic Bank-CA	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRC.PR.J	First Republic Bank-CA	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRC.PR.L	First Republic Bank	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRC.PR.M	First Republic Bank	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRC.PR.N	First Republic Bank Depositary 	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FRO	Frontline plc Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FRT	Federal Realty Investment Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FRT.PR.C	Federal Realty Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
FSI	Flexible Solutions International Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FSK	FS KKR Capital Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FSLY	Fastly Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FSM	Fortuna Mining Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FSP	Franklin Street Properties Corp.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FSS	Federal Signal Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTEV	FinTech Evolution Acquisition Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTI	TechnipFMC plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTK	Flotek Industries, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTRA	FutureCorp Space Acquisition 1 Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTRA.UN	FTRA.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTS	Fortis Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTV	Fortive Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTW	Presidio Production Company Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FTW.WT	First Trust Taiwan AlphaDEX® Fund WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FUBO	FuboTV Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FUL	H.B. Fuller Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FUN	Six Flags Entertainment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FURY	Fury Gold Mines Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FUSE	Fusemachines Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FVR	FrontView REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
FVRR	Fiverr International Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
FVT.UN	Fortress Value Acquisition Corp. III	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
G	Genpact Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GAB.PR.G	Gabelli Equity Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GAB.PR.H	Gabelli Equity Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GAB.PR.K	Gabelli Equity Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GAM.PR.B	General American Investors Co Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GAP	The Gap, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GAPA.UN	G&P Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
GATX	GATX Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GAU	Galiano Gold Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBCI	Glacier Bancorp Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBL	GAMCO Investors Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBLI	Global Indemnity Group LLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBR	New Concept Energy, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBTG	Global Business Travel Group Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GBX	The Greenbrier Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GCDT	Green Circle Decarbonize Technology Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GCI	Gannett Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GCO	Genesco Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GCTS	GCT Semiconductor Holding, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GCTS.WT	GCT Semiconductor Holding, Inc. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GD	General Dynamics Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GDDY	GoDaddy Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GDOT	Green Dot Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GDP	Goodrich Petroleum Corp	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GDV.PR.H	Gabelli Dividend & Income Trust-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GDV.PR.K	The Gabelli Dividend & Income Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GE	General Electric Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GEF	Greif Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GEF.B	Greif Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GEL	Genesis Energy, L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
GENC	Gencor Industries, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GENI	Genius Sports Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GEO	The GEO Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GETR	Getaround, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GETY	Getty Images Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GEV	GE Vernova Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GFF	Griffon Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GFI	Gold Fields Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GFL	GFL Environmental Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GFR	Greenfire Resources Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GGB	Gerdau S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GGG	Graco Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GGN.PR.B	GAMCO Global Gold Natural Resources & Income Trust	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GGT.PR.E	Gabelli Multimedia Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GGT.PR.G	Gabelli Multimedia Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GHC	Graham Holdings Co. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GHG	GreenTree Hospitality Group Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GHI	Greystone Housing Impact Investors LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
GHM	Graham Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GIB	CGI Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GIC	Global Industrial Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GIL	Gildan Activewear Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GIS	General Mills Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GIX	GigCapital9 Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GJH	STRATS Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GJO	STRATS Trust for Wal-Mart Inc. Preferred Stock 5.35372% Due 02/15/2030	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GJP	STRATS Preferred Stock 6.09456%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GJR	STRATS Trust for P&G 5.62678% 08/15/34 Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GJS	STRATS 0.9% Preferred Stock due 02/15/2033	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GJT	STRATS Preferred Stock 5.72678% Due 04/01/36	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GKOS	Glaukos Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GL	Globe Life Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLAS	Glass House Brands Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLDG	GoldMining Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLED	GalaxyEdge Acquisition Corp. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLED.UN	GalaxyEdge Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLOB	Globant S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLOP.PR.A	GasLog Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLOP.PR.B	GLOP 8.2 PERP PFD	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLOP.PR.C	GasLog Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLP	Global Partners LP Common Units	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
GL.PR.D	Globe Life Inc. 4.25% Junior Su	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLT	Magnera Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GLU.PR.A	Gabelli Global Utility & Income Trust	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLU.PR.B	Gabelli Global Utility & Income Trust	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GLW	Corning Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GM	General Motors Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GME	GameStop Corp. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GMED	Globus Medical Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GME.WT	GameStop Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GMRE.PR.A	Global Medical REIT Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GMRS	GMR Solutions Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GMTL	Guardian Metal Resources PLC ADS	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GNE	Genie Energy Ltd. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GNK	Genco Shipping & Trading Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GNL	Global Net Lease, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
GNL-D	Global Net Lease, Inc. 7.50% Series D Cumulative Redeemable Perpetual Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GNL-E	Global Net Lease, Inc. 7.375% Series E Cumulative Redeemable Perpetual Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GNL.PR.A	Global Net Lease Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GNL.PR.B	Global Net Lease Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GNRC	Generac Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GNS	Genius Group Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GNS.RT	Genius Group Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GNT.PR.A	GAMCO Natural Resources Gold & Income Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GNW	Genworth Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GOLD	Gold.com Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GOLF	Acushnet Holdings Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GOOS	Canada Goose Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GORO	Gold Resource Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GOTU	Gaotu Techedu Inc.	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GPC	Genuine Parts Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPGI	GPGI, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPI	Group 1 Automotive, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPJA	Georgia Power Co. Preferred Stock 5%, 10/01/2077	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GPK	Graphic Packaging Holding Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPL	Great Panther Mining Ltd	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPMT	Granite Point Mortgage Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
GPMT.PR.A	Granite Point Mortgage Trust Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GPN	Global Payments Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPOR	Gulfport Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPRK	GeoPark Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPS	The Gap, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPUS	Hyperscale Data, Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPUS-D	Hyperscale Data, Inc. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GPUS.PR.D	Hyperscale Data, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRAF	Graf Global Corp. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRAF.UN	Graf Industrial Corp	USD	NYSE	XASE	United States	Unit	2026-09-14 21:16:44.761313+00	\N
GRAM	Grana y Montero SAA	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GRBK	Green Brick Partners, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRBK.PR.A	Green Brick Partners, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRC	The Gorman-Rupp Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRDN	Guardian Pharmacy Services, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRMN	Garmin Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRND	Grindr Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRNT	Granite Ridge Resources, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GRO	Brazil Potash Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GROV	Grove Collaborative Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GROY	Gold Royalty Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GROY.WT	Gold Royalty Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GS	The Goldman Sachs Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GSBD	Goldman Sachs BDC, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GSHRF	Gold X2 Mining Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GSK	GSK plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
GSL	Global Ship Lease Inc Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GSL.PR.B	Global Ship Lease Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GS.PR.A	Goldman Sachs Group Inc-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GS.PR.C	Goldman Sachs Group Inc-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GS.PR.D	Goldman Sachs Group Inc-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GTE	Gran Tierra Energy Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GTES	Gates Industrial Corporation plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GTN	Gray Media Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GTN.A	Gray Media Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GTY	Getty Realty Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
GUT.PR.C	Gabelli Utility Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
GVA	Granite Construction Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GWH	ESS Tech, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GWRE	Guidewire Software Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GWW	W.W. Grainger Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
GXO	GXO Logistics, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
H	Hyatt Hotels Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HAE	Haemonetics Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HAFN	Hafnia Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HAL	Halliburton Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HASI	HA Sustainable Infrastructure Capital, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HAWK	HawkEye 360, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HAYW	Hayward Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HBB	Hamilton Beach Brands Holding Company Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HBM	Hudbay Minerals Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HCA	HCA Healthcare, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HCC	Warrior Met Coal, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HCI	HCI Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HCWC	Healthy Choice Wellness Corp. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HCXY	Hercules Capital Inc. Preferred Stock 6.25% 10/30/33	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HD	The Home Depot, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HDB	HDFC Bank Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HE	Hawaiian Electric Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HEI	HEICO Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HEI.A	Heico Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HESM	Hess Midstream LP Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HFRO.PR.A	Highland Income Fund	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HFRO.PR.B	Highland Funds I - Highland Opportunities and Income Fund	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HG	Hamilton Insurance Group Ltd. Class B Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HGTY	Hagerty, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HGV	Hilton Grand Vacations Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HHH	Howard Hughes Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HIG	The Hartford Insurance Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HIGA.UN	H.I.G. Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
HIG.PR.G	Hartford Financial Services Group Inc-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HII	Huntington Ingalls Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HIMS	Hims & Hers Health, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HIPO	Hippo Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HIW	Highwoods Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
HKD	AMTD Digital Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HL	Hecla Mining Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLF	Herbalife Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLI	Houlihan Lokey, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLIO	Helios Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLLY	Holley Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLN	Haleon Plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HL.PR.B	Hecla Mining Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HLSQ	Tessera Defense and Homeland Security Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLT	Hilton Worldwide Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HLX	Hornbeck Offshore Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HMC	Honda Motor Co Ltd Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HMLP.PR.A	Hoegh LNG Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HMN	Horace Mann Educators Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HMY	Harmony Gold Mining Company Limited - Depositary Receipt (Common Stock)	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HNGE	Hinge Health, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HNI	HNI Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HOG	Harley-Davidson, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HOMB	Home BancShares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HOS	Hornbeck Offshore Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HOV	Hovnanian Enterprises Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HP	Helmerich & Payne, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HPE	Hewlett Packard Enterprise Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HPE-C	Hewlett Packard Enterprise Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HPP	Hudson Pacific Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
HPP.PR.C	Hudson Pacific Properties, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HPQ	HP Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HR	Healthcare Realty Trust Incorporated	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
HRB	H&R Block Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HRI	Herc Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HRL	Hormel Foods Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HRTG	Heritage Insurance Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HSBC	HSBC Holdings plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HSHP	Himalaya Shipping Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HSLV	Highlander Silver Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HSY	The Hershey Company Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HTB	HomeTrust Bancshares Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HTFC	Horizon Technology Finance Corporation Preferred Stock 6.25%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
HTGC	Hercules Capital Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HTH	Hilltop Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HTPA.UN	Highland Transcend Partners I Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
HTT	High Templar Tech Limited American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HUBB	Hubbell Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HUBS	HubSpot, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HUGS.UN	USHG Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
HUM	Humana Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HUN	Huntsman Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HUSA	Houston American Energy Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HUYA	Huya Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
HVT	Haverty Furniture Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HVT.A	Haverty Furniture Companies, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HWM	Howmet Aerospace Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HXL	Hexcel Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HY	Hyster-Yale, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HYLN	Hyliion Holdings Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
HZO	MarineMax Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IACC	ION Acquisition Corp 3 Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IAG	IAMGOLD Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IAUX	i-80 Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IAUX.WT	i-80 Gold Corp. WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IBM	International Business Machines Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IBN	ICICI Bank Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
IBO	Impact BioMedical Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IBP	Installed Building Products, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IBTA	Ibotta Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ICE	Intercontinental Exchange, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ICL	ICL Group Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ICR-A	Inpoint Commercial Real Estate Income, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
ICR.PR.A	Inpoint Commercial Real Estate Income, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
IDA	IDACORP Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IDR	Idaho Strategic Resources Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IDT	IDT Corporation Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IE	Ivanhoe Electric Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IEX	IDEX Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IFF	International Flavors & Fragrances, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IFIN	Currenc Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IFS	Intercorp Financial Services Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IGC	IGC Pharma, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IGT	International Game Technology PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IH	iHuman Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
IHG	InterContinental Hotels Group PLC ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
IHS	IHS Holding Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IHT	InnSuites Hospitality Trust	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IIIN	Insteel Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IIPR	Innovative Industrial Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
IIPR.PR.A	Innovative Industrial Properties Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
IMAX	IMAX Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IMC	IMC Rare Earths Ltd	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IMO	Imperial Oil Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IMPX	AEA-Bridges Impact Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INDO	Indonesia Energy Corporation Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INFQ	Infleqtion Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INFQ.WT	INFQ.WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INFU	InfuSystem Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INFY	Infosys Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ING	ING Groep N.V. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
INGM	Ingram Micro Holding Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INGR	Ingredion Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INLX	Intellinetics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INN	Summit Hotel Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
INN-F	Summit Hotel Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
INN.PR.D	Summit Hotel Properties Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
INN.PR.E	Summit Hotel Properties Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
INN.PR.F	Summit Hotel Properties, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
INR	Infinity Natural Resources, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INSP	Inspire Medical Systems, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INSW	International Seaways, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INSW.PR.A	International Seaways Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
INTT	InTest Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INUV	Inuvo Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
INVH	Invitation Homes Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
INVX	Innovex International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IONQ	IonQ, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IOR	Income Opportunity Realty Investors, Inc.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
IOT	Samsara Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IP	International Paper Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IPB	Indexplus Trust Preferred 6.0518%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
IPI	Intrepid Potash, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IQV	IQVIA Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IR	Ingersoll Rand Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IRAB	Iris Acquisition Corp II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IRAB.UN	IRAB.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IRAB.WT	IRAB.WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IRM	Iron Mountain Incorporated	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
IRS	IRSA Inversiones y Representaciones S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
IRT	Independence Realty Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ISDR	Issuer Direct Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ISENF	IsoEnergy Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ISOU	IsoEnergy Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ISR	IsoRay Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IT	Gartner Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ITGR	Integer Holdings Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ITP	IT Tech Packaging Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ITRG	Integra Resources Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ITT	ITT Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ITUB	Itaú Unibanco Holding S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ITW	Illinois Tool Works Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IVC	Invacare Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IVR	Invesco Mortgage Capital Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
IVR.PR.C	Invesco Mortgage Capital Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
IVT	InvenTrust Properties Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
IVZ	Invesco Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
IX	ORIX Corporation Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
J	Jacobs Solutions Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JACS	Jackson Acquisition Company II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JACS.RI	Jackson Acquisition Company II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JACS.UN	Jackson Acquisition Company II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JAGU	Jaguar Uranium Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JBGS	JBG SMITH Properties	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
JBI	Janus International Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JBK	Corp-Backed Trust Certificates Series V 6.345% 02/15/2034 Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JBL	Jabil Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JBS	JBS N.V. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JBTM	JBT Marel Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JCI	Johnson Controls International plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JEF	Jefferies Financial Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JELD	JELD-WEN Holding, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JENA	Jena Acquisition Corporation II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JENA.UN	Jena Acquisition Corporation II	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
JHX	James Hardie Industries plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JILL	J.Jill, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JKS	JinkoSolar Holding Co., Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
JLL	Jones Lang LaSalle Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JMIA	Jumia Technologies AG Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
JMKE	Jersey Mike's Subs Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JNJ	Johnson & Johnson	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JOB	GEE Group Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JOBY	Joby Aviation, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JOE	The St. Joe Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JP	Jupai Holdings Ltd	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
JPM	JPMorgan Chase & Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.C	JPMorgan Chase & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.D	JPMorgan Chase & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.J	JPMorgan Chase & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.K	JPMorgan Chase & Co.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.L	JPMorgan Chase & Co.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JPM.PR.M	JPMorgan Chase & Co.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
JXN	Jackson Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
JXN-A	Jackson Financial Inc. Depositary Shares, each representing a 1/1,000th interest in a share of Fixed-Rate Reset Noncumulative Perpetual Preferred Stock, Series A	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KAHC.UN	KKR Acquisition Holdings I Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
KAI	Kadant Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KAPA	Kairos Pharma Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KAR	Openlane Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KB	KB Financial Group Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
KBDC	Kayne Anderson BDC Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KBH	KB Home	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KBR	KBR Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KCAC.UN	Kensington Capital Acquisition 	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KCAC.WT	KCAC.WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KCA.UN	Kensington Capital Acquisition Corp. VI	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KD	Kyndryl Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KEN	Kenon Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KEP	Korea Electric Power Corporation Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
KEX	Kirby Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KEY	KeyCorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KEY.PR.I	KeyCorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KEY.PR.J	KeyCorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KEY.PR.K	KeyCorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KEY.PR.L	KeyCorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KEYS	Keysight Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KFRC	Kforce Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KFS	Kingsway Financial Services Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KFY	Korn Ferry	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KGC	Kinross Gold Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KGS	Kodiak Gas Services Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KIM	Kimco Realty Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
KIM.PR.L	Kimco Realty Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KIM.PR.M	Kimco Realty Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KIM.PR.N	Kimco Realty Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KIND	Nextdoor Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KKR	Korro Bio, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KKR.PR.D	KKR & Co Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KKRS	KKR Group Finance Co. IX LLC Preferred Stock 4.625%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KKRT	KKR & Co. Inc. 6.875% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KLAR	Klarna Group plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KLC	KinderCare Learning Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KMI	Kinder Morgan Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KMPB	Kemper Corporation Preferred Stock 5.875%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KMPR	Kemper Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KMT	Kennametal Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KMX	CarMax Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KN	Knowles Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNF	Knife River Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNOP	KNOT Offshore Partners LP	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNRX	Knorex Ltd. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNSL	Kinsale Capital Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNTK	Kinetik Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KNX	Knight-Swift Transportation Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KO	The Coca-Cola Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KODK	Eastman Kodak Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KOF	Coca-Cola FEMSA, S.A.B. de C.V. - ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
KOP	Koppers Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KOS	Kosmos Energy Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KPET	KPET Ultra Paceline Corp. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KPET.UN	KPET Ultra Paceline Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KPET.WT	KPET Ultra Paceline Corporation WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KR	The Kroger Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KRC	Kilroy Realty Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
KREF	KKR Real Estate Finance Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
KREF-A	KKR Real Estate Finance Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
KREF.PR.A	KKR Real Estate Finance Trust Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KRG	Kite Realty Group Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
KRMN	Karman Holdings Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KRO	Kronos Worldwide, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KRSP	Rice Acquisition Corporation 3 Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KRSP.UN	Rice Acquisition Corporation 3	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KRSP.WT	KRSP.WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KSS	Kohl's Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KT	KT Corp. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
KTB	Kontoor Brands Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KTH	CORTS Peco Energy Capital Trust III Preferred Stock 8% Callable 2028	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KTN	CORTS Trust for Aon Cap Preferred Stock 8.205%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
KULR	KULR Technology Group, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KVUE	Kenvue Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KVYO	Klaviyo Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KWAC	Kingswood Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KWAC.UN	Kingswood Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
KWR	Quaker Houghton	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
KWY	Kingsway Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
L	Loews Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LAC	Lithium Americas Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LAD	Lithia Motors, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LADR	Ladder Capital Corp. Class A	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
LAIX	LAIX Inc	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LANV	Lanvin Group Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LAR	Lithium Argentina AG Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LAW	CS Disco, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LAZ	Lazard, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LB	LandBridge Company LLC Class A Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LBRT	Liberty Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LC	Happen, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LCII	LCI Industries	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LCLN	Lincoln International Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LCTX	Lineage Cell Therapeutics, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LDI	loanDepot, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LDOS	Leidos Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEA	Lear Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEG	Leggett & Platt, Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEGO.UN	LEGO.UN	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEGO.WT	LEGO.WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEN	Lennar Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEN.B	Lennar Corp. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEU	Centrus Energy Corp. Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEVI	Levi Strauss & Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LEV.WTA	LEV-WTA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LFC	China Life Insurance Co Ltd	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LFT	Lument Finance Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
LFT-A	Lument Finance Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
LFT.PR.A	Lument Finance Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
LGCY	Legacy Education Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LGL	The LGL Group, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LGPS	LogProstyle Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LGV	Longview Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LH	Labcorp Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LHX	L3Harris Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LII	Lennox International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LIII	Leo Holdings III Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LION	Lionsgate Studios Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LITB	LightInTheBox Holding Co., Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LLY	Eli Lilly and Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LMND	Lemonade Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LMT	Lockheed Martin Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LNC	Lincoln National Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LNC.PR.D	Lincoln National Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LND	BrasilAgro - Companhia Brasileira de Propriedades Agrícolas ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LNG	Cheniere Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LNN	Lindsay Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LOAR	Loar Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LOB	Live Oak Bancshares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LOB-A	Live Oak Bancshares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LOCL	Local Bounti Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LODE	Comstock Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LOMA	Loma Negra Compañía Industrial Argentina S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LOW	Lowe's Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LPA	Logistic Properties of the Americas	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LPG	Dorian LPG Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LPL	LG Display Co., Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LPX	Louisiana-Pacific Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LRN	Stride Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LSF	Laird Superfood, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LSPD	Lightspeed Commerce Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LTC	LTC Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
LTH	Life Time Group Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LTM	LATAM Airlines Group S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LU	Lufax Holding Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LUCK	Lucky Strike Entertainment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LUD	Luda Technology Group Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LUMN	Lumen Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LUV	Southwest Airlines Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LUXE	LuxExperience B.V. American Depositary Shares, each representing one Ordinary Share	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LVS	Las Vegas Sands Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LVWR	LiveWire Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LW	Lamb Weston Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LXFR	Luxfer Holdings PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LXP	LXP Industrial Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
LXP.PR.C	Lexington Realty Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
LXU	LSB Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LYB	LyondellBasell Industries N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LYG	Lloyds Banking Group plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
LYNX	Lyntris Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LYV	Live Nation Entertainment, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LZB	La-Z-Boy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
LZM	Lifezone Metals Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
M	Macy's Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MA	Mastercard Incorporated Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAA	Mid-America Apartment Communities, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MAA.PR.I	Mid-America Apartment Communities Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MAC	The Macerich Company	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MACC.UN	Mission Advancement Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
MAGN	Magnera Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAIA	MAIA Biotechnology, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAIN	Main Street Capital Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAIR	Madison Air Solutions Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAN	ManpowerGroup Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MANE	Veradermics, Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MANU	Manchester United plc Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAS	Masco Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MATV	Mativ Holdings Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MATX	Matson, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MAX	MediaAlpha Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MBC	MasterBrand, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MBGL	Mobility Global Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MBI	MBIA Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MC	Moelis & Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCB	Metropolitan Bank Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCD	McDonald's Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCK	McKesson Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCO	Moody's Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCRP	Micropolis AI Robotics	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCS	The Marcus Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MCY	Mercury General Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MD	Pediatrix Medical Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MDA	MDA Space Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MDT	Medtronic plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MDU	MDU Resources Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MEC	Mayville Engineering Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MED	Medifast Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MEG	Onterris, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MEI	Methode Electronics, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MER.PR.K	Bank of America Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MET	MetLife, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MET.PR.A	MetLife Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MET.PR.E	MetLife Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MET.PR.F	MetLife Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MFA	MFA Financial, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MFA-C	MFA Financial, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MFAN	MFA 8.875% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MFAO	MFA Financial Inc. 9% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MFA.PR.B	MFA Financial Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MFA.PR.C	MFA Financial, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MFC	Manulife Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MFG	Mizuho Financial Group, Inc. American Depositary Receipts	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MG	Mistras Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MGA	Magna International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MGLD	The Marygold Companies, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MGM	MGM Resorts International	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MGR	Affiliated Managers Group Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MGRB	Affiliated Managers Group Preferred Stock 4.75% 09/30/60	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MGRD	Affiliated Managers Group 4.2% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MGRE	Affiliated Managers Group 6.75% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MGY	Magnolia Oil & Gas Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MH	McGraw Hill, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MHH	Mastech Digital Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MHK	Mohawk Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MHLA	Maiden Holdings, Ltd.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MHNC	Maiden Holdings North America Ltd. 7.75% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MHO	M/I Homes, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MH.PR.A	Maiden Holdings Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MI	NFT Ltd. Class A Ordinary Share	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MIAX	Miami International Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MICC	The Magnum Ice Cream Company N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MIR	Mirion Technologies, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MITN	AG Mortgage Investment Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MITP	AG Mortgage Investment Trust Preferred Stock 9.5% 05/15/29	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MITQ	Moving iMage Technologies, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MITT	TPG Mortgage Investment Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MITT.PR.A	AG Mortgage Investment Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MITT.PR.B	AG Mortgage Investment Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MITT.PR.C	AG Mortgage Investment Trust Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MKC	McCormick & Company, Incorporated Non-Voting Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MKC.V	McCormick & Company, Incorporated Voting Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MKL	Markel Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MLI	Mueller Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MLM	Martin Marietta Materials Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MLP	Maui Land & Pineapple Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MLR	Miller Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MLSS	Milestone Scientific Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MMA	Mixed Martial Arts Group Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MMC	Marsh & McLennan Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MMI	Marcus & Millichap, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MMM	3M Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MMS	Maximus Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MNR	Mach Natural Resources LP Common Units representing Limited Partner Interests	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
MNSO	MINISO Group Holding Limited ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MNTN	MNTN Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MO	Altria Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOD	Modine Manufacturing Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOG.A	Moog Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOG.B	Moog Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOGU	Mogu Inc. American Depositary Shares (each representing 300 Class A Ordinary Shares)	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MOH	Molina Healthcare Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOS	The Mosaic Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MOV	Movado Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MP	MP Materials Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MPC	Marathon Petroleum Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MPLN	Claritev Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MPLX	MPLX LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
MPT	Medical Properties Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MPTI	M-tron Industries, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MPU	Mega Matrix Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MPW	Medical Properties Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MRK	Merck & Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MRP	Millrose Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
MRSH	Marsh & McLennan Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MRT	Marti Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MS	Morgan Stanley Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSA	MSA Safety Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSB	Mesabi Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
MSC	Studio City International Holdings Limited ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MSCI	MSCI Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSDL	Morgan Stanley Direct Lending Fund	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSGE	Madison Square Garden Entertainment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSGS	Madison Square Garden Sports Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSI	Motorola Solutions, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSIF	MSC Income Fund Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSM	MSC Industrial Direct Co., Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MSN	Emerson Radio Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.A	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.E	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.F	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.I	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.K	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.L	Morgan Stanley	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.O	Morgan Stanley Depositary Share	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MS.PR.P	Morgan Stanley	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MS-Q	Morgan Stanley Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MT	ArcelorMittal NY Registry Shares	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MTA	Metalla Royalty & Streaming Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTAL	Metals Acquisition Corp. II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTAL.UN	Metals Acquisition Corp	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
MTB	M&T Bank Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTB-H	M&T Bank Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTB-J	M&T Bank Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
MTB-K	M&T Bank Corporation	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MTB-L	M&T Bank Corporation	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MTBPL	M&T Bank Corporation Depositary Shs Repr 1/400th Non-Cum Perp Pfd Rg Shs Series L	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTB.PR.H	M&T Bank Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTD	Mettler-Toledo International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTDR	Matador Resources Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTEST	NYSE Texas, Inc. TEST	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTEST.A	MTEST.A	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTG	MGIC Investment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTH	Meritage Homes Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTL	Mechel PJSC	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MTL.PR.P	Mechel PJSC	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MTN	Vail Resorts Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTNB	Matinas BioPharma Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTNE	CH4 Natural Solutions Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTNE.UN	CH4 Natural Solutions Corporati	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTNE.WT	CH4 Natural Solutions Corp WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTR	Mesa Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
MTRN	Materion Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTUS	Metallus Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTW	The Manitowoc Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTX	Minerals Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MTZ	MasTec, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MUFG	Mitsubishi UFJ Financial Group, Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MUR	Murphy Oil Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MUSA	Murphy USA Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MUX	McEwen Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MWA	Mueller Water Products Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MWG	Multi Ways Holdings Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MX	Magnachip Semiconductor Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MXC	Mexco Energy Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MYE	Myers Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MYND	Mynd.ai, Inc. ADR	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
MYO	Myomo Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MYTE	Luxexperience B.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MZYX	MOZAYYX Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MZYX.UN	MOZAYYX Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
MZYX.WT	MZYX.WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NABL	N-able, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NAK	Northern Dynasty Minerals Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NAT	Nordic American Tankers Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NATL	NCR Atleos Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NBHC	National Bank Holdings Corp Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NBR	Nabors Industries Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NBY	Stablecoin Development Corporation Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NC	NACCO Industries, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NCDL	Nuveen Churchill Direct Lending Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NCL	Northann Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NCLH	Norwegian Cruise Line Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NCV.PR.A	AllianzGI Convertible & Income Fund	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NCZ.PR.A	AllianzGI Convertible & Income Fund II	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NE	Noble Corporation plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEE	NextEra Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEE.PR.N	NextEra Energy Capital Holdings Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NEE-S	NextEra Energy, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NEE-T	NextEra Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEE-U	NextEra Energy, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NEE-V	NextEra Energy, Inc.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
NEEXU	NextEra Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEM	Newmont Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEN	New England Realty Associates Limited Partnership	USD	NYSE	XASE	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
NET	Cloudflare, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEU	NewMarket Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEW	Puxin Ltd	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NEWP	New Pacific Metals Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NE.WTA	NE-WTA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NEXA	Nexa Resources S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NFG	National Fuel Gas Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NFGC	New Found Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NG	NovaGold Resources Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NGG	National Grid plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NGL	NGL Energy Partners LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
NGL.PR.B	NGL Energy Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NGL.PR.C	NGL Energy Partners LP	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NGS	Natural Gas Services Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NGVC	Natural Grocers by Vitamin Cottage, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NGVT	Ingevity Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NHC	National HealthCare Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NHI	National Health Investors, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NI	NiSource Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NIC	Nicolet Bankshares Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NILE	BitNile Holdings, Inc. Common S	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NILE.PR.D	BitNile Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NINE	Nine Energy Service, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NIO	NIO Inc. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NIQ	NIQ Global Intelligence plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NJR	New Jersey Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NKE	Nike, Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NL	NLI Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NLOP	Net Lease Office Properties	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NLY	Annaly Capital Management, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NLY-J	Annaly Capital Management, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NLY.PR.F	Annaly Capital Management Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NLY.PR.G	Annaly Capital Management Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NLY.PR.I	Annaly Capital Management Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NMAX	Newsmax Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NMG	Nouveau Monde Graphite Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NMM	Navios Maritime Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
NMR	Nomura Holdings, Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NNI	Nelnet Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NNN	NNN REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NNVC	NanoViricides, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOA	North American Construction Group Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOAH	Noah Holdings Limited Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NOC	Northrop Grumman Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOG	Northern Oil and Gas, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOK	Nokia Corporation Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NOMD	Nomad Foods Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOTE	FiscalNote Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOV	NOV Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NOW	ServiceNow Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NP	Neptune Insurance Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NPB	Northpointe Bancshares Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NPK	National Presto Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NPKI	NPK International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NPO	Enpro Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NPWR	Net Power Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NR	NPK International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NRDY	Nerdy Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NREF	NexPoint Real Estate Finance, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NREF-A	NexPoint Real Estate Finance, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NREF.PR.A	NexPoint Real Estate Finance, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NRG	NRG Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NRGV	Energy Vault Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NRP	Natural Resource Partners L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
NRT	North European Oil Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
NRUC	National Rural Utilities Cooperative Finance Corporation Preferred Stock, 5.5%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NRXS	NeurAxis, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NSC	Norfolk Southern Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NSP	Insperity, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NSRX	Nasus Pharma Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTB	The Bank of N.T. Butterfield & Son Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTEST	NTEST	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTEST.H	NTEST-H	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTEST.I	NTEST-I	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTIP	Network-1 Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTP	Nam Tai Property Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTR	Nutrien Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NTST	NETSTREIT Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NTZ	Natuzzi S.p.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NU	Nu Holdings Ltd. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NUE	Nucor Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NUS	Nu Skin Enterprises Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NUVB	Nuvation Bio Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVA.WT	NVA.WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVGS	Navigator Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVO	Novo Nordisk A/S Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NVR	NVR Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVRI	Enviri Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVS	Novartis AG Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NVST	Envista Holdings Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NVT	nVent Electric plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NWAX	New America Acquisition I Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NWAX.UN	New America Acquisition I Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NWAX.WT	New America Acquisition I Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NWG	NatWest Group plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
NWN	Northwest Natural Holding Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NX	Quanex Building Products Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NXB	NextBoat Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NXDR	Nextdoor Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NXDT	NexPoint Diversified Real Estate Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NXDT.PR.A	NexPoint Strategic Opportunities Fund	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
NXE	NexGen Energy Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NXRT	NexPoint Residential Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
NYC	American Strategic Investment Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NYCB	Flagstar Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
NYCB.PR.U	NEW YORK COMMUNITY CAP TR V PFD	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
NYT	New York Times Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
O	Realty Income Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
OAK.PR.A	Oaktree Capital Group LLC	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
OAK.PR.B	Oaktree Capital Group LLC	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
OBDC	Blue Owl Capital Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OBE	Obsidian Energy Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OBK	Origin Bancorp, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OC	Owens Corning	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OCAC	Ocean Capital Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OCAC.UN	Ocean Capital Acquisition Corpo	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OCAC.WT	Ocean Capital Acquisition Corporation WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OCANF	OceanaGold Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OCA.UN	Omnichannel Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
OCN	Ocwen Financial Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ODC	Oil-Dri Corporation of America	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ODV	Osisko Development Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OEC	Orion S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OFC	Corporate Office Properties Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
OFG	OFG Bancorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OFRM	Once Upon a Farm, PBC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGC	OceanaGold Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGCP	Empire State Realty OP, L.P. Series 60 Operating Partnership Units Representing Limited Partnership Interests	USD	NYSE	ARCX	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
OGE	OGE Energy Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGEN	Oragenics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGG	Osisko Gold Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGN	Organon & Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OGS	One Gas Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OHI	Omega Healthcare Investors Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
OI	O-I Glass, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OII	Oceaneering International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OIS	Oil States International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OKE	ONEOK, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OKLO	Oklo Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OLN	Olin Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OLP	One Liberty Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
OMC	Omnicom Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OMF	OneMain Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OMI	Owens & Minor Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ONDR	Sushi Ginza Onodera Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ONIT	Onity Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ONL	Orion Properties Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ONON	On Holding AG Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ONT	Onterris, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ONTO	Onto Innovation Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OOMA	Ooma Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPAD	Offerpad Solutions Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPFI	OppFi Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPHC	OptimumBank Holdings Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPLN	OPENLANE, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPP.PR.A	RiverNorth/DoubleLine Strategic Opportunity Fund, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
OPP.PR.B	RiverNorth/DoubleLine Strategic Opportunity Fund, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
OPP.PR.C	RiverNorth/DoubleLine Strategic	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPTT	Ocean Power Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPTU	Optimum Communications, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OPY	Oppenheimer Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OR	OR Royalties Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ORA	Ormat Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ORC	Orchid Island Capital, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
ORCL	Oracle Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ORCL-D	Oracle Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ORI	Old Republic International Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ORN	Orion Group Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OSCR	Oscar Health, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OSG	Octave Specialty Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OSK	Oshkosh Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OSTX	OS Therapies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OTAI	Starlink AI Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OTAI.UN	Starlink AI Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OTF	Blue Owl Technology Finance Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OTIS	Otis Worldwide Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OUT	OUTFRONT Media Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
OVV	Ovintiv Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OWL	Blue Owl Capital Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OWLT	Owlet, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OXM	Oxford Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OXY	Occidental Petroleum Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OXY.WT	Occidental Petroleum Corporatio	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
OZ	Belpointe PREP LLC	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
P	Everpure Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAAI	The Arena Group Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAAS	Pan American Silver Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAC	Grupo Aeroportuario del Pacífico SAB de CV ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PACE	TPG Pace Tech Opportunities Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PACK	Ranpak Holdings Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PACS	PACS Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAG	Penske Automotive Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAGS	PagSeguro Digital Ltd. Class A Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAII	Pyrophyte Acquisition Corp. II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAII.UN	Pyrophyte Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAII.WT	Pyrophyte Acquisition Corp. II WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAM	Pampa Energía S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PAPL	Pineapple Financial Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAR	Par Technology Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PARR	Par Pacific Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PATH	UiPath Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAY	Paymentus Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PAYC	Paycom Software, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PB	Prosperity Bancshares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PBA	Pembina Pipeline Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PBF	PBF Energy Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PBH	Prestige Consumer Healthcare Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PBI	Pitney Bowes Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PBI.PR.B	Pitney Bowes Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PBR	Petróleo Brasileiro S.A. - Petrobras	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PBR.A	Petroleo Brasileiro S.A. - Petrobras American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PBT	Permian Basin Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
PCG	PG&E Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.A	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.B	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.C	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.D	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.E	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.G	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.H	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.I	Pacific Gas & Electric Co	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PCG.PR.X	PG&E Corp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PCOR	Procore Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PCPC.UN	Periphas Capital Partnering Corporation	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
PD	PagerDuty, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PDM	Piedmont Realty Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PDPA	Pearl Diver Credit Co. Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PDS	Precision Drilling Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PEB	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PEB-G	Pebblebrook Hotel Trust 6.375% 	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEB-H	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PEB.PR.E	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEB.PR.F	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEB.PR.G	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEB.PR.H	Pebblebrook Hotel Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PED	PEDEVCO Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PEG	Public Service Enterprise Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PEI	Pennsylvania Real Estate Investment Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PEI.PR.B	Pennsylvania Real Estate Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEI.PR.C	Pennsylvania Real Estate Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEI.PR.D	Pennsylvania Real Estate Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PEN	Penumbra Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PERF	Perfect Corp. Class A Ordinary Share	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PEW	GrabAGun Digital Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PEW.WT	GrabAGun Digital Holdings Inc. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PFE	Pfizer Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PFGC	Performance Food Group Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PFH	Prudential Financial Inc. Preferred Stock 4.125%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PFLA	PennantPark Floating Rate Capital Ltd. 7.375% Notes Due 2031	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PFLT	PennantPark Floating Rate Capital Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PFS	Provident Financial Services, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PFSI	PennyMac Financial Services, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PG	Procter & Gamble Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PGR	The Progressive Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PGSS	Pegasus Digital Mobility Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PH	Parker-Hannifin Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PHG	Koninklijke Philips N.V. ADR	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PHGE	Tessera Defense and Homeland Security Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PHI	PLDT Inc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PHIN	PHINIA Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PHM	PulteGroup, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PHR	Phreesia Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PHXE-	Phoenix Energy One, LLC	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PIAI	Prime Impact Acquisition I	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PII	Polaris Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PINE	Alpine Income Property Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PINE-A	Alpine Income Property Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PINS	Pinterest, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PIPP.UN	Pine Island Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
PIPR	Piper Sandler Companies	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PJT	PJT Partners Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PK	Park Hotels & Resorts Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PKE	Park Aerospace Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PKG	Packaging Corporation of America	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PKX	POSCO Holdings Inc. American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PL	Planet Labs PBC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLAG	Planet Green Holdings Corp. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLD	Prologis, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PLG	Platinum Group Metals Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLGO	Pelagos Insurance Capital Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLNT	Planet Fitness Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLOW	Douglas Dynamics, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLUN	Plutonian Acquisition Corp II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLUN.UN	Plutonian Acquisition Corp II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PLX	Protalix BioTherapeutics, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PM	Philip Morris International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PMI	Picard Medical Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PMT	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PMT-C	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PMT.PR.A	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMT.PR.B	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMT.PR.C	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMTU	PennyMac Mortgage Investment Trust 8.50% Senior Notes due 2028	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMTV	Pennymac Mortgage Investment Trust 9% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMTW	PennyMac Mortgage Investment Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PMVC.UN	PMV Consumer Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
PNAQ.UN	Pinnacle Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PNC	The PNC Financial Services Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PNFP-A	Pinnacle Financial Partners, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PNFP-B	Pinnacle Financial Partners, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PNFP-C	Pinnacle Financial Partners, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PNM	PNM Resources Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PNNT	PennantPark Investment Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PNR	Pentair plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PNW	Pinnacle West Capital Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
POAS	Phaos Technology Holdings (Cayman) Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
POR	Portland General Electric Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
POST	Post Holdings, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PPG	PPG Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PPL	PPL Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PR	Permian Resources Corp Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRBM.UN	Parabellum Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
PRG	PROG Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRGO	Perrigo Company plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRH	Prudential Financial Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRI	Primerica Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRIF-K	Priority Income Fund, Inc. 7.00	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRIF-L	Priority Income Fund, Inc. 6.37	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRIF.PR.D	Priority Income Fund Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRIF.PR.K	Priority Income Fund, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRIF.PR.L	Priority Income Fund, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRIM	Primoris Services Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRK	Park National Corp. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRKS	United Parks & Resorts Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRLB	Proto Labs, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRM	Perimeter Solutions, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRMB	Primo Brands Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRMW	Primo Water Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRS	Prudential Financial Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PRSU	Pursuit Attractions and Hospitality, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PRT	PermRock Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
PRU	Prudential Financial, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSA	Public Storage	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PSA.PR.F	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.G	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.H	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.I	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.J	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.K	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.L	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.M	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.N	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.O	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.P	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.Q	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.R	Public Storage Depositary Share	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.S	Public Storage	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSA.PR.U	Public Storage	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSA-T	Public Storage	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PSBD	Palmer Square Capital BDC Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSB.PR.X	PS Business Parks Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSB.PR.Z	PS Business Parks Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSEC-A	Prospect Capital Corporation 5.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSEC.PR.A	Prospect Capital Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PSFE	Paysafe Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSN	Parsons Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSO	Pearson plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PSQH	PSQ Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PSTL	Postal Realty Trust Inc. Class A Common Stock	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PSX	Phillips 66	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTEST	PTEST	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTEST.X	PTEST-X	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTEST.Z	PTEST-Z	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTHS	Pelthos Therapeutics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTN	Palatin Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PTR	PetroChina Co Ltd	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PUK	Prudential plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
PUK.PR.	Prudential PLC	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PUK.PR.A	Prudential PLC	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PUMP	ProPetro Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PV	Primavera Capital Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PVH	PVH Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PVL	Permianville Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
PW	Power REIT	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
PW.PR.A	Power REIT	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PWR	Quanta Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PXED	Phoenix Education Partners Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
PYT	PreferredPlus Trust Series GSC2 Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
PZG	Paramount Gold Nevada Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
Q	Qnity Electronics Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QBTS	D-Wave Quantum Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QD	Qudian Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
QFTA	Quantum FinTech Acquisition Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QGEN	Qiagen N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QLEP	Quantum Leap Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QLEP.WT	Quantum Leap Acquisition Corp WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QNC	Quantum eMotion Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QRED	QuasarEdge Acquisition Corp. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QRED.UN	QuasarEdge Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QS	QuantumScape Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QSR	Restaurant Brands International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QTWO	Q2 Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QUAD	Quad/Graphics, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QXO	QXO Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
QXO-B	QXO, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
R	Ryder System Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RAC	Rithm Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RACE	Ferrari N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RAC.UN	Rithm Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RAC.WT	Rithm Acquisition Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RAL	Ralliant Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RAMP	LiveRamp Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RBA	RB Global Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RBC	RBC Bearings Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RBLX	Roblox Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RBOT	Vicarious Surgical Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RBRK	Rubrik Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RC	Ready Capital Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RCD	Ready Capital Corporation 9.00% Preferred Stock due 2029	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RC-E	Ready Capital Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RCFA.UN	RCF Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
RCI	Rogers Communications Inc. Class B	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RCL	Royal Caribbean Cruises Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RC.PR.C	Ready Capital Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RC.PR.E	Ready Capital Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RCUS	Arcus Biosciences, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RDDT	Reddit Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RDN	Radian Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RDS.A	Shell Plc Sponsored American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
RDW	Redwire Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RDY	Dr. Reddy's Laboratories Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
REA	Rare Earths Americas Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
REED	Reed's, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
REF	Reformation Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
REI	Ring Energy, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RELX	RELX PLC American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
REPX	Riley Exploration Permian, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RERE	ATRenew Inc. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
RES	RPC, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
REX	Rex American Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
REXR	Rexford Industrial Realty, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
REXR.PR.B	Rexford Industrial Realty Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
REXR.PR.C	Rexford Industrial Realty Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
REZI	Resideo Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RF	Regions Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RF-F	Regions Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RFL	Rafael Holdings Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RF.PR.C	Regions Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RF.PR.E	Regions Financial Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RGA	Reinsurance Group of America, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RGNT	Regentis Biomaterials Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RGR	Sturm, Ruger & Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RH	RH Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RHI	Robert Half Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RHP	Ryman Hospitality Properties, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RIG	Transocean Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RIO	Rio Tinto plc ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
RITM	Rithm Capital Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RITM-C	Rithm Capital Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RITM-D	Rithm Capital Corp. 7.00% Fixed	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RITM-E	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RITM-F	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RITM.PR.A	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RITM.PR.B	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RITM.PR.C	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RITM.PR.D	Rithm Capital Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RIV.PR.A	RiverNorth Opportunities Fund, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RJF	Raymond James Financial, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RKT	Rocket Companies Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RL	Ralph Lauren Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RLGT	Radiant Logistics, Inc. Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RLI	RLI Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RLJ	RLJ Lodging Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RLJ.PR.A	RLJ Lodging Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RLX	RLX Technology Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
RM	Regional Management Corp. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RMAX	Re/Max Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RMD	ResMed Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RNG	RingCentral, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RNGR	Ranger Energy Services, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RNR	RenaissanceRe Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RNR.PR.F	RenaissanceRe Holdings Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RNR.PR.G	RenaissanceRe Holdings Ltd.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RNST	Renasant Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ROG	Rogers Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ROK	Rockwell Automation Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ROL	Rollins Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ROLR	High Roller Technologies Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RPC	Ridgepost Capital Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RPM	RPM International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RPT	Rithm Property Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RPT.PR.C	Rithm Property Trust Inc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RRC	Range Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RRX	Regal Rexnord Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RS	Reliance, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RSG	Republic Services, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RSI	Rush Street Interactive, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RSKD	Riskified Ltd. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RTO	Rentokil Initial plc American Depositary Shares (each representing five Ordinary Shares)	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
RTX	RTX Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RVII	Robinhood Ventures Fund II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RVLV	Revolve Group Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RVP	Retractable Technologies, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RVTY	Revvity Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RWT	Redwood Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RWT-A	Redwood Trust Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RWTN	Redwood Trust Inc. 9.125% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RWTO	Redwood Trust Inc. 9% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RWTP	Redwood Trust Inc. 9.125% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
RWT.PR.A	Redwood Trust, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RWTQ	Redwood Trust, Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
RWTRP	Redwood Trust, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RWTS	Redwood Trust, Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
RY	Royal Bank of Canada	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RYAM	Rayonier Advanced Materials Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RYAN	Ryan Specialty Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RYDE	Ryde Group Ltd. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RYN	Rayonier Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
RYZ	Ryerson Holding Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
RZC	Reinsurance Group of America 7.125% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
S	SentinelOne Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SA	Seabridge Gold Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAC	Safeguard Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SACH	Sachem Capital Corp.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SACH-A	Sachem Capital Corp.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SACH.PR.A	Sachem Capital Corp.	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SAC.UN	Safeguard Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAC.WT	Safeguard Acquisition Corp. WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAFE	Safehold Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SAGU	Shreya Acquisition Group Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAGU.UN	Shreya Acquisition Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAH	Sonic Automotive Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAJ	Saratoga Investment Corp., 8% Preferred Stock, due 10/31/2027	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SAM	Boston Beer Company, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAMO	Samos Energy Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAMO.UN	Samos Energy Acquisition Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAN	Banco Santander, S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SAP	SAP SE Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SAR	Saratoga Investment Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SARO	StandardAero Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SAT	Saratoga Investment Corp. 6% Preferred Stock due 04/30/2027	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SAV	Saratoga Investment Corp 7.50% Preferred Stock due February 6, 2031	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SAY	Saratoga Investment Corp Preferred Stock 8.125%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SAZ	Saratoga Investment Corp 8.50% Notes due 2028	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SB	Safe Bulkers, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBDS	Solo Brands, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBEV	Endovia Health Sciences, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBH	Sally Beauty Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBMT	Silver Bow Mining Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SB.PR.C	Safe Bulkers Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SB.PR.D	Safe Bulkers Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SBR	Sabine Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
SBS	Companhia de Saneamento Básico do Estado de São Paulo - SABESP ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SBSI	Southside Bancshares Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBSW	Sibanye Stillwater Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SBXD	SilverBox Corp IV Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBXD.UN	SilverBox Corp IV	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBXD.WT	SilverBox Corp IV WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBXE	SilverBox Corp V Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBXE.UN	SilverBox Corp V	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SBXE.WT	SilverBox Corp V WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCCD	Sachem Capital Corp. 6.00% Notes due 2026	USD	NYSE	XASE	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
SCCE	Sachem Capital Corp. 6.00% Notes due 2027	USD	NYSE	XASE	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
SCCF	Sachem Capital Corp. 7.125% Preferred Stock	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCCG	Sachem Capital Corp. 8% Preferred Stock	USD	NYSE	XASE	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCCO	Southern Copper Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCE-M	SCE Trust VII 7.50% Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCE-N	SCE Trust VIII 6.95% Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCE.PR.G	SCE Trust II	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCE.PR.L	SCE Trust VI	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCHW	The Charles Schwab Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCHW.PR.D	Charles Schwab Corp-The	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCHW.PR.J	The Charles Schwab Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SCI	Service Corporation International	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCL	Stepan Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCM	Stellus Capital Investment Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SCPX	Scorpius Holdings Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SD	SandRidge Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SDHC	Smith Douglas Homes Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SDRL	Seadrill Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SE	Sea Limited Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SEAL-B	Seapeak LLC 8.50% Series B Fixe	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SEAL.PR.A	Seapeak LLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SEAL.PR.B	Seapeak LLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SEB	Seaboard Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SECZ	Securitize Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SEG	Seaport Entertainment Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SEI	Solaris Energy Infrastructure, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SENS	Senseonics Holdings Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SER	Serina Therapeutics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SES	SES AI Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SF	Stifel Financial Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SFB	Stifel Financial Corp. 5.2% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SFBS	ServisFirst Bancshares, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SFL	SFL Corporation Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SF.PR.B	Stifel Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SF.PR.C	Stifel Financial Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SF.PR.D	Stifel Financial Corp.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SG	Sweetgreen Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SGHC	Super Group (SGHC) Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SGI	Somnigroup International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SGU	Star Group, L.P.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SHAK	Shake Shack, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SHEL	Shell plc American Depositary Shares (Each representing two Ordinary shares)	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SHG	Shinhan Financial Group Co., Ltd. American Depositary Receipt	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SHO	Sunstone Hotel Investors, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SHO-H	Sunstone Hotel Investors, Inc. 	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SHO-I	Sunstone Hotel Investors, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SHO.PR.H	Sunstone Hotel Investors, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SHO.PR.I	Sunstone Hotel Investors, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SHW	The Sherwin-Williams Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SI	Shoulder Innovations, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SID	Companhia Siderurgica Nacional ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SIF	Sifco Industries, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SIG	Signet Jewelers Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SII	Sprott Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SIM	Grupo Simec, S.A.B. de C.V. Sponsored ADR Class B	USD	NYSE	XASE	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SIND	Sinda Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SITC	SITE Centers Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SITE	SiteOne Landscape Supply, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SJM	The J. M. Smucker Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SJT	San Juan Basin Royalty Trust	USD	NYSE	XNYS	United States	Trust	2026-09-14 21:16:44.761313+00	\N
SKE	Skeena Resources Limited	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SKIL	Skillsoft Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SKM	SK Telecom Co., Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SKT	Tanger Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SKY	Champion Homes, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SKYH	Sky Harbour Group Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SKYH.WT	Sky Harbour Group Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLB	SLB N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLF	Sun Life Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLG	SL Green Realty Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SLGN	Silgan Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLG.PR.I	SL Green Realty Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SLI	Standard Lithium Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLND	Southland Holdings Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLQT	SelectQuote Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLSR	Solaris Resources Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SLVM	Sylvamo Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SM	SM Energy Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMA	SmartStop Self Storage REIT, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SMBK	SmartFinancial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMC	Summit Midstream Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMFG	Sumitomo Mitsui Financial Group Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SMG	The Scotts Miracle-Gro Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMHI	Seacor Marine Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMJF	SMJ International Holdings Inc. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMLP	Summit Midstream Partners LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
SMP	Standard Motor Products Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMR	NuScale Power Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMRT	SmartRent Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMTS	Sierra Metals Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SMWB	Similarweb Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SN	SharkNinja, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNA	Snap-on Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNAP	Snap Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNDA	Sonida Senior Living, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNDR	Schneider National Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNN	Smith & Nephew plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SNOW	Snowflake Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNSC	SunScout Holding Limited Class A	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SNUS-H	Santander Holdings USA, Inc.	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SNUS-I	Santander Holdings USA, Inc.	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SNX	TD SYNNEX Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SO	The Southern Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOAR	Volato Group, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOBO	South Bow Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOC	Sable Offshore Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOI	Solaris Energy Infrastructure, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOJC	Southern Co. Preferred Stock 5.25%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SOJD	Southern Company 4.95% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SOJE	Southern Company Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SOJF	Southern Company 6.5% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SOLV	Solventum Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOMN	Southern Company	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
SON	Sonoco Products Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SONY	Sony Group Corp. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SOS	SOS Ltd	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOUL	Soulpower Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SOUL.UN	SOULPOWER ACQUISITION CORP UNIT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPB	Spectrum Brands Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPCE	Virgin Galactic Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPE.PR.C	Special Opportunities Fund, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPG	Simon Property Group Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SPGI	S&P Global Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPG.PR.J	Simon Property Group Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SPH	Suburban Propane Partners, L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
SPHR	Sphere Entertainment Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPIR	Spire Global, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPMA	Sound Point Meridian Capital 8% Preferred Stock Due 2029	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SPME	Sound Point Meridian Capital, Inc. 7.875% Series B Preferred Shares due 2030	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SPNT	SiriusPoint Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPOT	Spotify Technology S.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPRU	Spruce Power Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SPXC	SPX Technologies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SQ	Block, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SQM	Sociedad Química y Minera de Chile S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SQNS	Sequans Communications S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SR	Spire Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SRE	Sempra	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SREA	Sempra Preferred Stock 5.75%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SRFM	Surf Air Mobility Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SRG	Seritage Growth Properties Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SRG.PR.A	Seritage Growth Properties	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SRI	Stoneridge, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SRJN	Spire Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
SRL	Scully Royalty Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SRXH	SRx Health Solutions Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SSB	SouthState Bank Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SSD	Simpson Manufacturing Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SSL	Sasol Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SSMR	Sunshine Silver Mining & Refining Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SST	System1, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SSTK	Shutterstock Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ST	Sensata Technologies Holding plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STAG	STAG Industrial, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
STC	Stewart Information Services Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STDN	Standard Nuclear Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STE	STERIS plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STEM	Stem, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STG	Sunlands Technology Group ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
STLA	Stellantis N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STM	STMicroelectronics N.V.	USD	NYSE	XNYS	United States	Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
STN	Stantec Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STNG	Scorpio Tankers Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STRW	Strawberry Fields REIT, Inc.	USD	NYSE	XASE	United States	REIT	2026-09-14 21:16:44.761313+00	\N
STT	State Street Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STT.PR.G	State Street Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
STUB	StubHub Holdings Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STVN	Stevanato Group S.p.A.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STWD	Starwood Property Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
STXS	Stereotaxis Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
STZ	Constellation Brands Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SU	Suncor Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SUI	Sun Communities, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
SUN	Sunoco LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
SUNB	Sunbelt Rentals Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SUP	Superior Industries International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SUPV	Grupo Supervielle S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SUZ	Suzano S.A. - Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
SVM	Silvercorp Metals Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SVMLF	Sovereign Metals Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SVV	Savers Value Village, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SW	Smurfit WestRock Plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SWK	Stanley Black & Decker Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SWX	Southwest Gas Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SXC	SunCoke Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SXI	Standex International Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SXT	Sensient Technologies Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYF	Synchrony Financial	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYF.PR.A	Synchrony Financial	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
SYF.PR.B	Synchrony Financial	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYK	Stryker Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYN	Synthetic Biologics Inc	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYNX	Silynxcom Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
SYY	Sysco Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
T	AT&T Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TAC	TransAlta Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TAK	Takeda Pharmaceutical Co Ltd ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TAL	TAL Education Group ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TALO	Talos Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TAP	Molson Coors Beverage Company Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TAP.A	Molson Coors Beverage Co. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TBB	AT&T Inc. Preferred Stock 5.35%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TBBB	BBB Foods Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TBI	TrueBlue, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TBN	Tamboran Resources Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TCI	Transcontinental Realty Investors, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TCNNF	Trulieve Cannabis Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TCPA	TransCanada PipeLines Limited Cumulative Redeemable First Preferred Shares, Series 11	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TD	Toronto-Dominion Bank	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDAY	USA TODAY Co., Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDC	Teradata Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDG	TransDigm Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDOC	Teladoc Health Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDS	Telephone and Data Systems, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDS.PR.U	Telephone and Data Systems, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TDS.PR.V	Telephone and Data Systems, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TDW	Tidewater Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TDY	Teledyne Technologies Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TE	T1 Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TECK	Teck Resources Ltd Class B	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TEL	TE Connectivity plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TELFY	Telefónica S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TEN	Tsakos Energy Navigation Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TEN-E	Tsakos Energy Navigation Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TEN-F	Tsakos Energy Navigation Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TEO	Telecom Argentina S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TEVA	Teva Pharmaceutical Industries Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TEVJF	Teva Pharmaceutical Industries Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TEX	Terex Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TFC	Truist Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TFC.PR.I	Truist Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TFC.PR.O	Truist Financial Corporation De	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TFC.PR.R	Truist Financial Corporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TFII	TFI International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TFIN.PR.	Triumph Financial, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TFPM	Triple Flag Precious Metals Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TFX	Teleflex Incorporated	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TG	Tredegar Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGB	Trekor Metals Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGE	The Generation Essentials Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGEN	Tecogen Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGE.WT	The Generation Essentials Group	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGLS	Tecnoglass Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TGS	Transportadora de Gas del Sur S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TGT	Target Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
THC	Tenet Healthcare Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
THG	The Hanover Insurance Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
THM	International Tower Hill Mines Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
THO	Thor Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TIC	TIC Solutions, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TII	Titan Mining Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TIMB	TIM S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TISI	Team, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TJX	The TJX Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TK	Teekay Corporation Ltd. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TKC	Turkcell Iletisim Hizmetleri A.S. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TKO	TKO Group Holdings, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TKR	The Timken Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TLK	PT Telkom Indonesia (Persero) Tbk ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TLYS	Tilly's Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TM	Toyota Motor Corporation Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TMDE	TMD Energy Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TME	Tencent Music Entertainment Group ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TMO	Thermo Fisher Scientific Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TMP	Tompkins Financial Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TMQ	Trilogy Metals Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNC	Tennant Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNET	TriNet Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNK	Teekay Tankers Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNL	Travel + Leisure Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNP	Tsakos Energy Navigation Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TNP.PR.E	Tsakos Energy Navigation Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TNP.PR.F	Tsakos Energy Navigation Ltd	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TOL	Toll Brothers, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TONT	Graf Global Corp. Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TONT.UN	TONT.UN	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TONT.WT	Graf Global Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TOON	Kartoon Studios Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TOPP	Toppoint Holdings Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TOPS	Top Ships Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TOST	Toast, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TOVX	Theriva Biologics Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TP	Ticketplus Ltd.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPB	Turning Point Brands, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPC	Tutor Perini Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPET	Trio Petroleum Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPL	Texas Pacific Land Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPR	Tapestry Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
T.PR.A	AT&T Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
T.PR.C	Tutor Perini Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TPTS	Terra Property Trust, Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
TPVG	TriplePoint Venture Growth BDC Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TPX	Tempur Sealy International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TR	Tootsie Roll Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRAD	APEX Tech Acquisition Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRAD.UN	TRAD.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRAK	ReposiTrak Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRC	Tejon Ranch Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TREX	Trex Company, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRGP	Targa Resources Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRIS	Tristar Acquisition I Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRLV	Trulieve Cannabis Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRN	Trinity Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRNI	Trinity Capital Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
TRNO	Terreno Realty Corporation	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
TRNZ	Trinity Capital Inc.	USD	NYSE	XNYS	United States	Exchange-Traded Note	2026-09-14 21:16:44.761313+00	\N
TROX	Tronox Holdings plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRP	TC Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRT	Trio-Tech International Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRTN-D	Triton International Limited 6.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN-E	Triton International Limited 5.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN-G	Triton International Limited	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.A	Triton International Ltd-Bermuda	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.B	Triton International Ltd-Bermuda	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.C	Triton International Ltd-Bermuda	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.D	Triton International Limited	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.E	Triton International Limited	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRTN.PR.F	Triton International Ltd	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRTX	TPG RE Finance Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
TRTX-C	TPG RE Finance Trust, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
TRTX.PR.C	TPG RE Finance Trust, Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TRU	TransUnion	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRV	The Travelers Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TRX	TRX Gold Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TS	Tenaris S.A. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TSLX	Sixth Street Specialty Lending, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TSM	Taiwan Semiconductor Manufacturing Company Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TSN	Tyson Foods, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TSQ	Townsquare Media, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TT	Trane Technologies plc	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TTAM	Titan America SA	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TTC	The Toro Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TTE	TotalEnergies SE	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TTI	Tetra Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TU	TELUS Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TUYA	Tuya Inc. American Depositary Shares, each representing one Class A Ordinary Share	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TV	Grupo Televisa, S.A.B. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TVC	Tennessee Valley Authority Preferred Stock 2.134% Due 06/01/2028	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TVE	Tennessee Valley Authority Preferred Stock 2.216%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TWI	Titan International Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TWLO	Twilio Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TWND.UN	Tailwind Acquisition Corp.	USD	NYSE	XNYS	United States	Unit	2026-09-14 21:16:44.761313+00	\N
TWO	Two Harbors Investment Corp.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
TWOD	Two Harbors Investment Corp. 9.375% Senior Notes due 2030	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TWO.PR.A	Two Harbors Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TWO.PR.B	Two Harbors Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TWO.PR.C	Two Harbors Investment Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
TX	Ternium S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
TXNM	TXNM Energy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TXO	TXO Partners, L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
TXT	Textron Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TYL	Tyler Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
TY.PR.	Tri-Continental Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
U	Unity Software Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UA	Under Armour Inc Class C	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAA	Under Armour Inc Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAC	United Acquisition Corp. I Class A Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAC.UN	UAC.UN	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAC.WT	UAC.WT	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAMY	United States Antimony Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UAN	CVR Partners, LP Common Units Representing Limited Partner Interests	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
UAVS	AgEagle Aerial Systems, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UBER	Uber Technologies Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UBS	UBS Group AG	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UCB	United Community Banks, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UDR	UDR Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
UE	Urban Edge Properties	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
UEC	Uranium Energy Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UFI	Unifi, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UGI	UGI Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UGP	Ultrapar Participações S.A. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
UHAL	U-Haul Holding Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UHAL.B	U-Haul Holding Company Series N Non-Voting Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UHS	Universal Health Services Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UHT	Universal Health Realty Income Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
UI	Ubiquiti Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UIS	Unisys Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UL	Unilever PLC Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ULS	UL Solutions Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UMAC	Unusual Machines Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UMC	United Microelectronics Corp. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
UMH	UMH Properties Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
UMH.PR.D	UMH Properties Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
UNF	UniFirst Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UNFI	United Natural Foods Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UNH	UnitedHealth Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UNM	Unum Group	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UNMA	Unum Group 6.25% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
UNP	Union Pacific Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UP	Wheels Up Experience Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UPS	United Parcel Service, Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
URG	Ur-Energy Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
URI	United Rentals Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USAC	USA Compression Partners, L.P.	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
USAS	Americas Gold and Silver Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USB	U.S. Bancorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.A	US Bancorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.H	US Bancorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.P	US Bancorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.Q	U.S. Bancorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.R	U.S. Bancorp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
USB.PR.S	U.S. Bancorp	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USFD	US Foods Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USM	U.S. Cellular Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USNA	USANA Health Sciences Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
USPH	U.S. Physical Therapy, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UTI	Universal Technical Institute, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UTL	Unitil Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UTZ	Utz Brands, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UUU	Universal Safety Products, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UUUU	Energy Fuels Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UVE	Universal Insurance Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UVV	Universal Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UWMC	UWM Holdings Corporation Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
UZD	United States Cellular Corporation 6.25% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
UZE	United States Cellular Corporation Preferred Stock 5.5%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
UZF	U.S. Cellular Corporation 5.5% Preferred Stock	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
V	Visa Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VAC	Marriott Vacations Worldwide Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VACI	Viking Acquisition Corp. I Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VACI.UN	Viking Acquisition Corp. I	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VACI.WT	Viking Acquisition Corp. I WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VAL	Valaris Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VALE	Vale S.A. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VATE	Innovate Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VECA	Vernal Capital Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VECA.UN	Vernal Capital Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VEEV	Veeva Systems Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VEL	Velocity Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VENU	Venu Holding Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VET	Vermilion Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VFC	VF Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VG	Venture Global Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VGII	Virgin Group Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VGNT	Versigent PLC	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VGZ	Vista Gold Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VHC	VirnetX Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VHI	Valhi Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VICI	VICI Properties Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VII.UN	Viking Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VIK	Viking Holdings Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VINE	Amaze Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VIPS	Vipshop Holdings Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VIRT	Virtu Financial Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VIST	Vista Energy, S.A.B. de C.V. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VIV	Telefônica Brasil S.A. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VLN	Valens Semiconductor Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VLO	Valero Energy Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VLRS	Controladora Vuela Compañía de Aviación, S.A.B. de C.V. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VLTO	Veralto Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VMC	Vulcan Materials Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VMI	Valmont Industries, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VMRK	Vivmark Residential	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VNCE	Vince Holding Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VNO	Vornado Realty Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VNO-N	Vornado Realty Trust 5.25% Seri	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VNO-O	Vornado Realty Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VNO.PR.L	Vornado Realty Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VNO.PR.M	Vornado Realty Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VNO.PR.N	Vornado Realty Trust 5.25% Seri	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VNO.PR.O	Vornado Realty Trust	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VNRX	VolitionRx Limited	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VNT	Vontier Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VNTG	Vantage Corp Class A Ordinary Shares	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VOYA	Voya Financial Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VOYA.PR.B	Voya Financial Inc	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
VOYG	Voyager Technologies Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VPG	Vishay Precision Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VRMK	Equity Residential	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VRT	Vertiv Holdings Co Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VRTS	Virtus Investment Partners, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VSH	Vishay Intertechnology, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VST	Vistra Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VSTS	Vestis Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VSXY	Victoria's Secret & Co.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VTAK	Catheter Precision Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VTEX	VTEX Class A Common Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VTMX	Corporación Inmobiliaria Vesta, S.A.B. de C.V. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
VTOL	Bristow Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VTR	Ventas, Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
VTS	Vitesse Energy Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VVV	Valvoline Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VVX	V2X Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VYX	NCR Voyix Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VZ	Verizon Communications Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
VZLA	Vizsla Silver Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
W	Wayfair Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WAB	Wabtec Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WAL	Western Alliance Bancorporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WAL.PR.A	Western Alliance Bancorporation	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WAT	Waters Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WBI	WaterBridge Infrastructure LLC Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WBS	Webster Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WBS.PR.F	Webster Financial Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WBS.PR.G	Webster Financial Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WBX	Wallbox N.V. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WCC	WESCO International, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WCN	Waste Connections, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WD	Walker & Dunlop Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WDH	Waterdrop Inc. American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
WDS	Woodside Energy Group Ltd ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
WEAV	Weave Communications Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WEC	WEC Energy Group Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WELL	Welltower Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
WENC	West Enclave Merger Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WENC.UN	West Enclave Merger Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WES	Western Midstream Partners, LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
WEX	WEX Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WF	Woori Financial Group Inc. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
WFC	Wells Fargo & Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.A	Wells Fargo & Company Depositar	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.C	Wells Fargo & Company	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.D	Wells Fargo & Company	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.L	Wells Fargo & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.Y	Wells Fargo & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFC.PR.Z	Wells Fargo & Co	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WFG	West Fraser Timber Co. Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WGO	Winnebago Industries Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WH	Wyndham Hotels & Resorts Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WHD	Cactus Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WHG	Westwood Holdings Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WHK	WhiteHawk Minerals Corp Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WHR	Whirlpool Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WHR-A	Whirlpool Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WIT	Wipro Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
WK	Workiva Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WKC	World Kinect Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WLK	Westlake Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WLKP	Westlake Chemical Partners LP	USD	NYSE	XNYS	United States	Limited Partnership	2026-09-14 21:16:44.761313+00	\N
WLTH	Wealthfront Corporation	USD	NYSE	ARCX	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WLY	John Wiley & Sons, Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WLYB	John Wiley & Sons, Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WM	Waste Management Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WMB	The Williams Companies, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WMK	Weis Markets, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WMS	Advanced Drainage Systems, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WNC	Wabash National Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WOLF	Wolfspeed Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WOR	Worthington Enterprises Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WPAC	White Pearl Acquisition Corp. Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WPAC.UN	White Pearl Acquisition Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WPC	W. P. Carey Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
WPM	Wheaton Precious Metals Corp.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WPP	WPP plc Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
WRB	W. R. Berkley Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WRB.PR.E	WR Berkley Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WRB.PR.F	WR Berkley Corp	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WRB.PR.G	W.R. Berkley Corporation 4.25% 	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WRB.PR.H	W.R. Berkley Corporation 4.125%	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
WRBY	Warby Parker Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WRE	Washington Real Estate Investment Trust	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
WRN	Western Copper and Gold Corporation	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WS	Worthington Steel Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WSM	Williams-Sonoma, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WSO	Watsco Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WSO.B	Watsco Inc. Class B Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WST	West Pharmaceutical Services Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WT	WisdomTree, Inc. Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WTI	W&T Offshore Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WTM	White Mountains Insurance Group, Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WTRG	Essential Utilities Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WTS	Watts Water Technologies, Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WTTR	Select Water Solutions Inc. Class A	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WU	The Western Union Company	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WWR	Westwater Resources Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WWW	Wolverine World Wide, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
WY	Weyerhaeuser Co.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
WYY	WidePoint Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XFLH	XFLH Capital Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XFLH.UN	XFLH.UN	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XHR	Xenia Hotels & Resorts Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
XIFR	XPLR Infrastructure, LP Common Units	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XOM	ExxonMobil Holdings Corporation Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XPER	Xperi Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XPEV	XPeng Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
XPL	Solitario Resources Corp.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XPO	XPO, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XPOF	Xponential Fitness Inc Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XPRO	Expro Group Holdings N.V.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XRN	Chiron Real Estate Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
XRN-A	Chiron Real Estate Inc.	USD	NYSE	XNYS	United States	Preferred Stock	2026-09-14 21:16:44.761313+00	\N
XRN-B	Chiron Real Estate Inc.	USD	NYSE	XNYS	United States	REIT	2026-09-14 21:16:44.761313+00	\N
XTND	Xtend AI Robotics, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XTNT	Xtant Medical Holdings, Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XXI	Twenty One Capital Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XYF	X Financial American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
XYL	Xylem Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XYZ	Block Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
XZO	Exzeo Group, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YALA	Yalla Group Limited American Depositary Shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
YCBD	cbdMD Inc.	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YCY	AA Mission Acquisition Corp. II Class A Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YCY.UN	AA Mission Acquisition Corp. II	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YCY.WT	AA Mission Acquisition Corp. II WT	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YELP	Yelp Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YETI	YETI Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YEXT	Yext Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YMM	Full Truck Alliance Co. Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
YOU	Clear Secure Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YPF	YPF Sociedad Anónima Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
YRD	Yiren Digital Ltd. Sponsored ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
YSG	Yatsen Holding Ltd. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
YSS	York Space Systems Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YUM	Yum! Brands Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
YUMC	Yum China Holdings, Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZBH	Zimmer Biomet Holdings Inc.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZDGE	Zedge Inc. Class B Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZEPP	Zepp Health Corporation American Depositary Shares, each representing sixteen Class A ordinary shares	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ZETA	Zeta Global Holdings Corp. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZGN	Ermenegildo Zegna N.V. Ordinary Shares	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZH	Zhihu Inc. - ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ZIM	ZIM Integrated Shipping Services Ltd.	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZIP	ZipRecruiter Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZKH	ZKH Group Ltd ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ZONE	CleanCore Solutions Inc. Class B Common Stock	USD	NYSE	XASE	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZTO	ZTO Express (Cayman) Inc. ADR	USD	NYSE	XNYS	United States	American Depositary Receipt	2026-09-14 21:16:44.761313+00	\N
ZTS	Zoetis Inc. Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZTST	ZTST	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZVIA	Zevia PBC Class A Common Stock	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
ZWS	Zurn Elkay Water Solutions Corporation	USD	NYSE	XNYS	United States	Common Stock	2026-09-14 21:16:44.761313+00	\N
AACB	Artius II Acquisition Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACBR	Artius II Acquisition Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACG	ATA Creativity Global	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AACI	Armada Acquisition Corp. III Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACO	Abony Acquisition Corp. I Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACOU	Advancit Acquisition Corp. I	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACP	Apogee Acquisition Corp Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AACPR	Apogee Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AAL	American Airlines Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AAME	Atlantic American Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AAOI	Applied Optoelectronics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AAON	AAON, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AAPG	Ascentage Pharma Group International	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AAPL	Apple Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AARD	Aardvark Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AATC	Autoscope Technologies Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABAT	American Battery Technology Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABCL	AbCellera Biologics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABEO	Abeona Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABL	Abacus Global Management, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABLV	Able View Global Inc. Class B Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABNB	Airbnb Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABOS	Acumen Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABSI	Absci Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABTC	Gryphon Digital Mining, Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABTS	Abits Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABUS	Arbutus Biopharma Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABVC	ABVC Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ABVX	Abivax SA Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ACAA	Averin Capital Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACAB	Abpro Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACAD	Acadia Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACB	Aurora Cannabis Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACCL	Acco Group Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACDC	ProFrac Holding Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACET	Adicet Bio, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACFN	Acorn Energy Inc. Common Stock	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACGC	ACP Holdings Acquisition Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACGL	Arch Capital Group Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACGLN	Arch Capital Group Ltd. 4.55% Non-Cumulative Preferred Shares, Series G	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ACGLO	Arch Capital Group Ltd. 5.45% Non-Cumulative Preferred Shares, Series F	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ACHC	Acadia Healthcare Company, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACHV	Achieve Life Sciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACIC	American Coastal Insurance Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACIU	AC Immune SA	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACIW	ACI Worldwide, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACLS	Axcelis Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACMR	ACM Research, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACNB	ACNB Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACNT	Ascent Industries Co.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACOG	Alpha Cognition Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACON	Aclarion, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACRS	Aclaris Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACRV	Acrivon Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACRX	AcelRx Pharmaceuticals Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACST	Grace Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACT	Enact Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACTG	Acacia Research Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACTU	Actuate Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ACXP	Acurx Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAG	Adagene Inc. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ADAM	Adamas Trust Inc.	USD	NASDAQ	XNMS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
ADAMG	Adamas Trust, Inc.	USD	NASDAQ	XNGS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
ADAMH	New York Mortgage Trust, Inc. - 9.875% Senior Notes Due 2030	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAMI	Adamas Trust, Inc.	USD	NASDAQ	XNGS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
ADAMK	Adamas Trust, Inc. 9.6% Senior Notes Due 2031	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ADAML	New York Mortgage Trust, Inc. - 6.875% Series F Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock, $0.01 par value per share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAMM	New York Mortgage Trust, Inc. - 7.875% Series E Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAMN	New York Mortgage Trust, Inc. - 8.00% Series D Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAMO	Adamas Trust, Inc.	USD	NASDAQ	XNGS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
ADAMZ	New York Mortgage Trust, Inc. - 7.000% Series G Cumulative Redeemable Preferred Stock, $0.01 par value per share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADAP	Adaptimmune Therapeutics plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ADBE	Adobe Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADBT	Advasa Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADEA	Adeia Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADGI	Adagio Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADGM	Adagio Medical Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADI	Analog Devices Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADIL	Adial Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADMA	ADMA Biologics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADOC	Edoc Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADP	Automatic Data Processing Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADPT	Adaptive Biotechnologies Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADSE	ADS-TEC Energy Plc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADSK	Autodesk Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADTN	ADTRAN Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADUR	Aduro Clean Technologies Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADUS	Addus HomeCare Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADV	Advantage Solutions Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADVB	Advanced Biomed Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ADXN	Addex Therapeutics Ltd ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AEAQ	Activate Energy Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEBI	Aebi Schmidt Holding AG Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEC	Anfield Energy Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEHL	Antelope Enterprise Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEHR	Aehr Test Systems, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEI	Alset Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEIS	Advanced Energy Industries Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEMD	Aethlon Medical, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AENT	Alliance Entertainment Holding Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEP	American Electric Power Company, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AERT	Aeries Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AESP	Aeon Acquisition I Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AESPR	Aeon Acquisition I Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEVA	Aeva Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AEYE	AudioEye, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFCG	Advanced Flower Capital Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFJK	Aimei Health Technology Co., Ltd. Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFJKR	Aimei Health Technology Co., Ltd. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFRI	Forafric Global PLC	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFRM	Affirm Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AFYA	Afya Ltd Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGCC	Agencia Comercial Spirits Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGEN	Agenus Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGFY	RYTHM Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGIO	Agios Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGMB	AgomAb Therapeutics NV American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AGMH	AGM Group Holdings Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGNC	AGNC Investment Corp.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
AGNCL	AGNC Investment Corp. 7.75% Series B Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AGNCM	AGNC Investment Corp. 6.875% Series D Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AGNCN	AGNC Investment Corp. 9.67459% Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AGNCO	AGNC Investment Corp. 10.1219% Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AGNCP	AGNC Investment Corp. 6.125% Series F Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AGNCZ	AGNC Investment Corp. Depositary Shs Repr 1/1000th Cum Conv Red Perp Pfd Registered Shs Ser H	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGNT	AGNT, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGPU	Predictive Oncology Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGRI	Avax One Technology Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGRZ	Agroz Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AGYS	Agilysys Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AHCO	AdaptHealth Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AHG	Akso Health Group ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AHMA	Ambitions Enterprise Management Co. L.L.C	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AHPA	Avista Public Acquisition Corp. II	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIAI	AIAI Holdings Corporation Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIB	AIB Acquisition Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIBZ	Bitzero Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIDX	20/20 Biolabs, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIEV	Thunder Power Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIFA	All In FutureTech Alliance Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIFC	AI Financial Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIFF	Firefly Neuroscience Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIFU	AIFU Inc. Class A Ordinary Share	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIHS	Valor Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIIO	Robo.ai Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIIOW	NWTN Inc. Warrant	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIIR	Air Holdings Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIMD	Ainos, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIOS	NiSun International Enterprise Development Group Co., Ltd. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIOT	PowerFleet, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIP	Arteris Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRE	reAlpha Tech Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRG	Airgain Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRJ	AirJoule Technologies Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRO	AIRO Group Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRS	AirSculpt Technologies, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRT	Air T, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIRTP	Air T Funding Preferred Stock 8% 06/07/2049	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
AISP	Airship AI Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIXC	AIxCrypto Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AIXI	Xiao-I Corporation American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AKAM	Akamai Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AKAN	Akanda Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AKBA	Akebia Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AKTS	Akoustis Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AKTX	Akari Therapeutics Plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ALAB	Astera Labs, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALAR	Alarum Technologies Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ALCE	Alternus Clean Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALCO	Alico Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALCY	Alchemy Investments Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALDF	Aldel Financial II Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALDX	Aldeyra Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALEC	Alector Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALF	Centurion Acquisition Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALGM	Allegro MicroSystems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALGN	Align Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALGS	Aligos Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALGT	Allegiant Travel Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALHC	Alignment Healthcare, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALIS	Calisa Acquisition Corp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALISR	Calisa Acquisition Corp Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALKS	Alkermes plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALKT	Alkami Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALLO	Allogene Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALLR	Allarity Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALLT	Allot Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALM	Almonty Industries Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALMR	Alamar Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALMS	Alumis Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALMU	Aeluma, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALNT	Allient Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALNY	Alnylam Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALOT	AstroNova Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALOV	Aldabra 4 Liquidity Opportunity Vehicle Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALOY	Blackboxstocks Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALP	Alpha Compute Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALPS	Alps Group Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALPX	Alpex Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALPXR	Alpex Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALRM	Alarm.com Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALRS	Alerus Financial Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALT	Altimmune, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALTI	AlTi Global, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALTO	Alto Ingredients Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALVO	Alvotech SA	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALVR	Kalaris Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALXO	ALX Oncology Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ALZN	Alzamend Neuro, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMAC	AMR Resources Acquisition Corp Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMAL	Amalgamated Financial Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMAN	Amanat Acquisition Corp Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMAT	Applied Materials Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMBA	Ambarella Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMBR	Amber International Holding Ltd. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AMCI	AMC Robotics Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMCX	AMC Global Media Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMD	Advanced Micro Devices Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMGN	Amgen Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMIX	Autonomix Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMKR	Amkor Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMLX	Amylyx Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMOD	Alpha Modus Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMPG	AmpliTech Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMPGZ	AmpliTech Group Inc. Series B Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMPH	Amphastar Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMPL	Amplitude Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMRK	Gold.com Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMRN	Amarin Corporation plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AMRX	Amneal Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMSC	American Superconductor Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMSF	Amerisafe Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMSS	AMASS Brands Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMST	Amesite Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMTX	Aemetis Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AMZN	Amazon.com Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANAB	AnaptysBio, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANDE	The Andersons, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANGH	Anghami Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANGI	Angi Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANGIV	Angi Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANGO	AngioDynamics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANIK	Anika Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANIP	Ani Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANIX	Anixa Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANL	Adlai Nortye Group Ltd. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ANNA	AleAnna Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANNX	Annexon Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANPA	Rich Sparkle Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANSC	Agriculture & Natural Solutions Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANTA	Antalpha Platform Holding Company Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANTE	Yueda Digital Holding Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANTX	AN2 Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ANY	Sphere 3D Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AOSL	Alpha & Omega Semiconductor Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AOUT	American Outdoor Brands Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APA	APA Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APAC	StoneBridge Acquisition II Corporation Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APACR	StoneBridge Acquisition II Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APDN	Applied DNA Sciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APEI	American Public Education, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APGE	Apogee Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
API	Agora, Inc. Sponsored ADR Class A	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
APLD	Applied Digital Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APLM	Apollomics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APM	Aptorum Group Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APMC	AmperCap Acquisition Company	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APMCR	AmperCap Acquisition Co. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APMD	Apnimed, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APMI	AxonPrime Infrastructure Acquisition Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APOG	Apogee Enterprises, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APP	AppLovin Corporation Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APPF	AppFolio Inc Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APPN	Appian Corp Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APPS	Digital Turbine, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APRE	Aprea Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APUR	Aperture AC Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APURR	Aperture AC Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APVO	Aptevo Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APWC	Asia Pacific Wire & Cable Corporation Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APXT	Apex Treasury Corporation Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
APYX	Apyx Medical Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AQB	AquaBounty Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AQMS	Aqua Metals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AQST	Aquestive Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARAI	Arrive AI Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARAY	Accuray Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARBB	ARB IOT Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARBE	Arbe Robotics Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARBK	Argo Blockchain Plc American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ARCB	ArcBest Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARCC	Ares Capital Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARCI	Appliance Recycling Centers of America Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARCL	ARC Group Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARCLR	ARC Group Acquisition I Corp Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARCT	Arcturus Therapeutics Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARDS	Aridis Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARDX	Ardelyx Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AREC	American Resources Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARGX	argenx SE American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ARHS	Arhaus, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARIZ	Arisz Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARKO	ARKO Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARKR	Ark Restaurants Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARLP	Alliance Resource Partners, L.P.	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
ARM	Arm Holdings plc ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AROW	Arrow Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARQ	Arq, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARQQ	Arqit Quantum Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARQT	Arcutis Biotherapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARRY	Array Technologies, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARTC	Art Technology Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARTL	Artelo Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARTNA	Artesian Resources Corp. Class A Non-Voting Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARTV	Artiva Biotherapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARTW	Art's-Way Manufacturing Co., Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARVN	Arvinas, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARWR	Arrowhead Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARXS	Arxis Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ARYD	ARYA Sciences Acquisition Corp IV	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASBP	Aspire Biopharma Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASLE	AerSale Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASMB	Assembly Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASML	ASML Holding N.V. NY Registered Shares	USD	NASDAQ	XNGS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ASND	Ascendis Pharma A/S	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASO	Academy Sports and Outdoors, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASPC	A SPAC III Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASPCR	A SPAC III Acquisition Corp. Right	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASPI	ASP Isotopes Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASPS	Altisource Portfolio Solutions S.A. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASPU	Aspen Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASRV	AmeriServ Financial Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASST	Strive, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTC	Astrotech Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTE	Astec Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTH	Astrana Health Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTI	Ascent Solar Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTL	Algoma Steel Group Inc. Common Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASTS	AST SpaceMobile Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASUR	Asure Software Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ASYS	Amtech Systems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATAI	AtaiBeckley Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATAT	Atour Lifestyle Holdings Limited Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ATAX	America First Multifamily Investors LP	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
ATCX	Atlas Technical Consultants Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATEC	Alphatec Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATER	Aterian Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATEX	Anterix Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATGL	Alpha Technology Group Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATHE	Alterity Therapeutics Ltd ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ATHR	Aether Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATIF	ATIF Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATII	Archimedes Tech SPAC Partners II Co.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATLC	Atlanticus Holdings Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATLCL	Atlanticus Holdings Corp. 6.125% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ATLCP	Atlanticus Holdings Corporation 7.625% Series B Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ATLCZ	Atlanticus Holdings Corp. Preferred Stock 9.25%	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ATLO	Ames National Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATLQ	JAB Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATLQR	JAB Acquisition Corp I Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATLX	Atlas Lithium Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATNI	ATN International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATOM	Atomera Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATOS	Atossa Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATPC	Agape ATP Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATRA	Atara Biotherapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATRC	AtriCure Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATRO	Astronics Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATTT	Atlas Trinity Tech Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATXG	Addentax Group Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATXI	Avenue Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ATYR	aTyr Pharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUBN	Auburn National Bancorporation, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUC	ATIF Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUDC	AudioCodes Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUGO	Aura Minerals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUID	authID Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUPH	Aurinia Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUR	Aurora Innovation Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AURA	Aura Biosciences, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AURE	Aurelion Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUTL	Autolus Therapeutics plc ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AUUD	Auddia Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUVI	Applied UV, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AUVIP	Applied UV Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVAH	Aveanna Healthcare Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVAT	Avalanche Treasury Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVAV	AeroVironment, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVBH	Avidbank Holdings, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVBP	ArriVent BioPharma, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVCO	Avalon GloboCare Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVGO	Broadcom Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVIR	Atea Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVLN	Avalyn Pharma Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVNW	Aviat Networks, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVO	Mission Produce Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVPT	AvePoint Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVR	Anteris Technologies Global Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVT	Avnet Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVTE	Jade Biosciences Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVTX	Avalo Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AVXL	Anavex Life Sciences Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AWH	Aspira Women's Health Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AWRE	Aware, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXG	Solowin Holdings Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXGN	Axogen, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXIN	Axiom Intelligence Acquisition Corp 1 Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXINR	Axiom Intelligence Acquisition Corp 1 Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXON	Axon Enterprise, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXSM	Axsome Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AXTI	AXT Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AYA	Aya Gold & Silver Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AYRO	Fabric.AI, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AYTU	Aytu BioPharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AZ	A2Z Cust2Mate Solutions Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AZI	Autozi Internet Technology (Global) Ltd. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AZIO	Azio AI Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AZN	AstraZeneca PLC American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
AZRX	AzurRx BioPharma Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
AZTA	Azenta, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BACC	Blue Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BACCR	Blue Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BACK	Imac Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BAER	Bridger Aerospace Group Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BAFN	BayFirst Financial Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BAND	Bandwidth Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BANF	BancFirst Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BANFP	BFC Capital Trust II 7.20% Cumulative Trust Preferred Securities	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BANL	CBL International Ltd. Class B Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BANR	Banner Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BAOS	Baosheng Media Group Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BATRA	Atlanta Braves Holdings, Inc. Series A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BATRK	Atlanta Braves Holdings Inc. Series C Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBBY	Neighborhood Intelligence, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBCP	Concrete Pumping Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBCQ	Bleichroeder Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBGI	Beasley Broadcast Group, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBIG	Vinco Ventures Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBIO	BridgeBio Pharma Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBLG	Bone Biologics Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBNX	Beta Bionics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBOT	BridgeBio Oncology Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BBSI	Barrett Business Services, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCAB	BioAtla Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCAL	California BanCorp Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCAN	Femto Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCAR	D. Boral ARC Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCAX	Bicara Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCBP	BCB Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCCQ	Bleichroeder Acquisition Corp. III Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCDA	BioCardia, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCG	Binah Capital Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCIC	BCP Investment Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCML	BayCom Corp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCOW	1895 Bancorp of Wisconsin Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCPC	Balchem Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCRX	BioCryst Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCTX	BriaCell Therapeutics Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BCYC	Bicycle Therapeutics plc - ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BDCI	BTC Development Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BDMD	Baird Medical Investment Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BDRX	Biodexa Pharmaceuticals plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BDSX	Biodesix, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BDTX	Black Diamond Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEAG	Bold Eagle Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEAGR	Bold Eagle Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEAM	Beam Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEAT	HeartBeam, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEEM	Beam Global	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BEEP	Mobile Infrastructure Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BELFA	Bel Fuse Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BELFB	Bel Fuse Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BENF	Beneficient	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BETR	Better Home & Finance Holding Company Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BFC	Bank First Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BFI	BurgerFi International Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BFRG	BullFrog AI Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BFRI	Biofrontera Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BFST	Business First Bancshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGC	BGC Group, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGDE	Big Digital Energy, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGIN	Bgin Blockchain Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGL	Blue Gold Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGLC	BioNexus Gene Lab Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGM	BGM Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BGMS	Cyclacel Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHAT	Blue Hat Interactive Entertainment Technology	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHAV	BHAV Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHAVR	BHAV Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHF	Brighthouse Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHFAL	Brighthouse Financial, Inc. 6.25% Junior Subordinated Notes due 2058	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BHFAM	Brighthouse Financial, Inc. 4.625% Non-Cumulative Preferred Stock, Series D	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BHFAN	Brighthouse Financial, Inc. 5.375% Non-Cumulative Preferred Stock, Series C	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BHFAO	Brighthouse Financial, Inc. 6.75% Non-Cumulative Preferred Stock, Series B, Depositary Shares (1/1,000th Per Share)	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BHFAP	Brighthouse Financial, Inc. 6.600% Non-Cumulative Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BHRB	Burke & Herbert Financial Services Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHSE	Bull Horn Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BHST	BioHarvest Sciences Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIAF	BioAffinity Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIDU	Baidu Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BIDWR	Tribeca Strategic Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIGC	BigCommerce Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIIB	Biogen Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BILI	Bilibili Inc. Sponsored ADR Class Z	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BIOA	BioAge Labs, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIOT	Biotech Acquisition Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIOX	Bioceres Crop Solutions Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIRD	Smartbird Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BITF	Bitfarms Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIVI	BioVie Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIXI	Bitcoin Infrastructure Acquisition Corp Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BIYA	Baiya International Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BJDX	Bluejay Diagnostics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BJRI	BJ's Restaurants, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BKHA	Black Hawk Acquisition Corporation Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BKHAR	Black Hawk Acquisition Corporation Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BKNG	Booking Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BKR	Baker Hughes Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BKYI	BIO-key International, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BL	BlackLine, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLAC	Bellevue Life Sciences Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLBD	Blue Bird Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLBX	REalloys Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLDE	Strata Critical Medical, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLDP	Ballard Power Systems Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLFS	BioLife Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLIN	Bridgeline Digital, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLIV	BeLive Holdings	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLKB	Blackbaud Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLLN	BillionToOne Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLMN	Bloomin' Brands, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLNE	Beeline Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLNK	Blink Charging Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLRK	Bluerock Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLRX	BioLineRx Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BLSM	BlossomHill Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLTE	Belite Bio, Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BLUW	Blue Water Acquisition Corp. III Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLZE	Backblaze, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BLZR	Trailblazer Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMBL	Bumble Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMEA	Biomea Fusion Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMGL	Basel Medical Group Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMHL	Bluemount Holdings Limited Class B Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMM	Blue Moon Metals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMR	Beamr Imaging Ltd. Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMRA	Biomerica Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMRC	Bank of Marin Bancorp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BMRN	BioMarin Pharmaceutical Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNAI	Brand Engagement Network Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNC	CEA Industries Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNCWW	CEA Industries Inc. Warrant	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNGO	Bionano Genomics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNKK	Bonk Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNR	Burning Rock Biotech Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BNRG	Brenmiller Energy Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNTC	Benitec Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BNTX	BioNTech SE American Depositary Share	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BOCN	Blue Ocean Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOF	BranchOut Food Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOKF	BOK Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOLD	Boundless Bio Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOLT	Bolt Biotherapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BON	Bon Natural Life Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOOM	DMC Global Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOSC	B.O.S. Better Online Solutions Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOT	RoboStrategy, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOTJ	Bank of the James Financial Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BOXL	Boxlight Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPAC	Blueport Acquisition Ltd Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPACR	Blueport Acquisition Ltd. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPOP	Popular, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPOPM	Popular Capital Trust II 6.125% Cumulative Monthly Income Trust Preferred Securities	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BPRN	Princeton Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPTH	Bio-Path Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BPYPM	Brookfield Property Partners L.P. 6.25% Class A Cumulative Redeemable Perpetual Preferred Units, Series 1	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BPYPN	Brookfield Property Partners L.P. 5.75% Class A Cumulative Redeemable Perpetual Preferred Units Series 3	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BPYPO	Brookfield Property Partners L.P. 6.375% Class A Cumulative Redeemable Perpetual Preferred Units Series 2	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BPYPP	Brookfield Property Partners L.P. 6.50% Class A Cumulative Redeemable Perpetual Preferred Units, Series 1	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BRAG	Bragg Gaming Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRAI	Braiin Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRCB	Black Rock Coffee Bar Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BREW	Craft Brew Alliance Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BREZ	Breeze Holdings Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BREZR	Breeze Holdings Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRFH	Barfresh Food Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRID	Bridgford Foods Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRKL	Brookline Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRKR	Bruker Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRKRP	Bruker Corporation 6.375% Mandatory Convertible Preferred Stock, Series A	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BRLS	Borealis Foods Inc. Class A Common Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRLT	Brilliant Earth Group, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRNS	Barinthus Biotherapeutics plc American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BRNX	BrenX Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRP	BRP Inc. Subordinate Voting Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRPM	B Riley Principal Merger Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRR	ProCap Financial, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRTM	B&R Technology Merger Corp. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRTX	BioRestorative Therapies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRUN	Boost Run Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRUNW	Boost Run Inc. Warrant	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRVE	Braveheart Bio, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BRZE	Braze, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSAA	Best SPAC I Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSAAR	BEST SPAC I Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSBK	Bogota Financial Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSEM	BioStem Technologies Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSET	Bassett Furniture Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSGA	Blue Safari Group Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSGM	Streamex Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSIIW	Black Spade Acquisition II Co	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSIN	Big Sky Industrial Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSP	Bending Spoons S.p.A.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSRR	Sierra Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSVN	Bank7 Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BSY	Bentley Systems, Incorporated Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTAI	BioXcel Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTBD	BT Brands, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTBT	Bit Digital Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTCS	BTCS Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTCT	BTC Digital Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTDR	Bitdeer Technologies Group Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTMD	Biote Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTOC	Armlogi Holding Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTOG	Bit Origin Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTQ	BTQ Technologies Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTSG	BrightSpring Health Services, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BTSGU	BrightSpring Health Services, Inc. 6.75% Preferred Stock due 2027	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BTTX	Better Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BUJA	Bukit Jalil Global Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BULL	Webull Corporation Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BUSE	First Busey Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BUSEP	First Busey Corporation 8.25% Series B Non-Cumulative Perpetual Preferred Stock, Depositary Shares, each representing a 1/40th interest in a share	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BUUU	BUUU Group Limited Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BVC	BitVentures Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BVFL	BV Financial, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BVS	Bioventus Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWAQ	Blue World Acquisition Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWAY	BrainsWay Ltd. Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BWB	Bridgewater Bancshares, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWBBP	Bridgewater Bancshares Preferred Stock 5.875% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
BWEN	Broadwind Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWFG	Bankwell Financial Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWIN	The Baldwin Insurance Group, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BWMN	Bowman Consulting Group Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BXBL	Boxabl Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BYAH	Park Ha Biological Technology Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BYFC	Broadway Financial Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BYND	Beyond Meat Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BYRN	Byrna Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BYSI	BeyondSpring Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BZ	Kanzhun Ltd ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
BZAI	Blaize Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BZFD	BuzzFeed Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
BZUN	Baozun Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CAAS	China Automotive Systems, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CABA	Cabaletta Bio Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CABR	Caring Brands Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAC	Camden National Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CACC	Credit Acceptance Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CADL	Candel Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAES	Cantor Equity Partners VII, Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAI	Caris Life Sciences, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAII	Collective Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAKE	The Cheesecake Factory Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CALA	Calithera Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CALC	CalciMedica, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CALM	Cal-Maine Foods, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAMP	Camp4 Therapeutics Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAMT	Camtek Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAN	Canaan Inc. - ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CAPA	HighCape Capital Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAPN	Cayson Acquisition Corp Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAPNR	Cayson Acquisition Corp Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAPR	Capricor Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAPS	Capstone Holding Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAQ	Cambridge Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAR	Avis Budget Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CARE	Carter Bankshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CARG	CarGurus Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CARL	Carlsmed Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CART	Maplebear Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CASH	Pathward Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CASS	Cass Information Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CAST	FreeCast Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CASY	Casey's General Stores, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CATY	Cathay General Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBAT	CBAK Energy Technology Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBC	Central Bancompany, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBFV	CB Financial Services Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBIO	Crescent Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBK	Commercial Bancgroup, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBLL	Ceribell Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBNK	Capital Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBRG	Chain Bridge I	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBRL	Cracker Barrel Old Country Store, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBRS	Cerebras Systems Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBSH	Commerce Bancshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CBUS	Cibus Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCAP	Crescent Capital BDC Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCB	Coastal Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCBG	Capital City Bank Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCCC	C4 Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCCS	CCC Intelligent Solutions Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCCT	Columbus Circle Capital Corp. III Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCEC	Capital Clean Energy Carriers Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCEP	Coca-Cola Europacific Partners PLC	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCG	Cheche Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCHH	CCH Holdings Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCII	Cohen Circle Acquisition Corp. II Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCLD	CareCloud Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCNC	Code Chain New Continent Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCNE	CNB Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCNEP	CNB Financial Corporation 7.125% Series A Non-Cumulative Perpetual Preferred Stock Depositary Shares	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CCOI	Cogent Communications Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCSI	Consensus Cloud Solutions, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCTG	CCSC Technology International Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CCXI	ChemoCentryx Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CD	Chindata Group Holdings Ltd	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CDEV	Centennial Resource Development Inc-DE	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDIO	Cardio Diagnostics Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDLX	Cardlytics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDNA	CareDx, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDNL	Cardinal Infrastructure Group Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDNS	Cadence Design Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDRO	Codere Online Luxembourg, S.A.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDT	CDT Equity Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDTG	CDT Environmental Technology Investment Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDW	CDW Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDXC	Niagen Bioscience Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDXS	Codexis Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDZI	Cadiz Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CDZIP	Cadiz Inc. Preferred Stock 8.875% Perpetual A	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CECE	Ceco Environmental Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CECO	CECO Environmental Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEG	Constellation Energy Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CELC	Celcuity Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CELH	Celsius Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CELU	Celularity Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CELZ	Creative Medical Technology Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CENN	Cenntro Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CENT	Central Garden & Pet Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CENTA	Central Garden & Pet Company Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CENX	Century Aluminum Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEPF	Cantor Equity Partners IV, Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEPL	Capstone Energy+ Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEPO	Cantor Equity Partners I, Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEPS	Cantor Equity Partners VI Inc Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEPV	Cantor Equity Partners V, Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CERS	Cerus Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CERT	Certara Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CETU	Cetus Capital Acquisition Corp. - Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CETX	Cemtrex Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CETY	Clean Energy Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CEVA	Ceva, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CFBK	CF Bankshares Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CFFI	C&F Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CFFN	Capitol Federal Financial, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CG	The Carlyle Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGABL	Carlyle Finance LLC 4.625% Senior Notes due 2061	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CGBD	Carlyle Secured Lending, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGC	Canopy Growth Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGCF	Cartesian Growth Corporation IV Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGEM	Cullinan Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGEN	Compugen Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGNT	Cognyte Software Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGNX	Cognex Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGON	CG Oncology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGTL	Creative Global Technology Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CGTX	Cognition Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHA	Chagee Holdings Ltd. American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CHAR	Charlton Aria Acquisition Corporation Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHARR	Charlton Aria Acquisition Corporation Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHCI	Comstock Holding Companies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHCO	City Holding Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHDN	Churchill Downs Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHEC	Chenghe Acquisition III Co. Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHEF	The Chefs' Warehouse, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHEK	Check-Cap Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHGA	Change Agents Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHKP	Check Point Software Technologies Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHMG	Chemung Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHNR	China Natural Resources, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHPG	ChampionsGate Acquisition Corporation Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHPGR	ChampionsGate Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHR	Cheer Holding, Inc. Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHRD	Chord Energy Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHRN	ChronoScale Holdings Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHRS	Coherus Oncology, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHRW	C.H. Robinson Worldwide Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHSCL	CHS Inc. 7.50% Class B Cumulative Redeemable Preferred Stock, Series 4	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHSCM	CHS Inc. 6.75% Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHSCN	CHS Inc. 7.10% Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHSCO	CHS Inc. 7.875% Cumulative Redeemable Preferred Stock, Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHSCP	CHS Inc. 8% Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHSN	Chanson International Holding Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHTR	Charter Communications Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CHTRP	Charter Communications, Inc. Series A Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CHYM	Chime Financial Inc. Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIFR	Cipher Digital Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIGI	Colliers International Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIGL	Concorde International Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIIT	Tianci International Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CINF	Cincinnati Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CING	Cingulate Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CISO	CISO Global Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CISS	C3is Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIVB	Civista Bancshares Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CIZN	Citizens Holding Company	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CJET	Digital Currency X Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CJJD	Ridgetech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CJMB	Callan JMB Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLAQ	CleanTech Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLAR	Clarus Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLBK	Columbia Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLBT	Cellebrite DI Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLDX	Celldex Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLFD	Clearfield, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLGN	CollPlant Biotechnologies Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLIK	Click Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLIR	ClearSign Technologies Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLLS	Cellectis S.A. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CLMB	Climb Global Solutions Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLMT	Calumet, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLNE	Clean Energy Fuels Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLNN	Clene Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLOV	Clover Health Investments, Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLPS	CLPS Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLPT	ClearPoint Neuro Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLRB	Cellectar Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLRO	ClearOne, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLSK	CleanSpark, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLSN	Celsion Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLST	Catalyst Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLVLY	Clinuvel Pharmaceuticals Ltd. American Depositary Shares	USD	NASDAQ	XNAS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CLVR	Clever Leaves Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLWT	Euro Tech Holdings Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CLYM	Climb Bio Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMBM	Cambium Networks Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMCO	Columbus McKinnon Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMCSA	Comcast Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMCT	Creative Media & Community Trust Corporation	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
CME	CME Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMII	CM Life Sciences II Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMMB	Chemomab Therapeutics Ltd. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CMND	Clearmind Medicine Inc. Common Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMPO	GPGI, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMPR	Cimpress plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMPS	Compass Pathways plc - ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CMPX	Compass Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMRA	Comera Life Sciences Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMRC	Commerce.com, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMTL	Comtech Telecommunications Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CMTV	Community Bancorp Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNCK	Coincheck Group N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNDT	Conduent Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNET	ZW Data Action Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNEY	CN Energy Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNFR	Presurance Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNOB	ConnectOne Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNOBP	ConnectOne Bancorp, Inc. 5.25% Fixed Rate Reset Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
CNSP	CNS Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNSY	Cerenome Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNTB	Connect Biopharma Holdings Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNTN	Canton Strategic Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNTQ	Chardan NexTech Acquisition 2 Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNTX	Context Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNTY	Century Casinos, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNVCF	BIOHARVEST SCIENCES INC.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNVS	Cineverse Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNXC	Concentrix Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNXN	PC Connection, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CNXU	Conexeu Sciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COAG	Hemab Therapeutics Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COCH	Envoy Medical Inc Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COCO	The Vita Coco Company, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COCP	Cocrystal Pharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CODA	Coda Octopus Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CODX	Co-Diagnostics Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COFS	ChoiceOne Financial Services, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COGT	Cogent Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COHU	Cohu, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COIN	Coinbase Global Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COKE	Coca-Cola Consolidated Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COLA	Columbus Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COLAR	Columbus Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COLB	Columbia Banking System, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COLL	Collegium Pharmaceutical, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COLM	Columbia Sportswear Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COMM	CommScope Holding Company, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COMS	ComSovereign Holding Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COMSP	ComSovereign Holding Corp. - 9.	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
COO	The Cooper Companies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COOL	Corner Growth Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COOT	Australian Oilseeds Holdings Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CORT	Corcept Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CORZ	Core Scientific, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COSM	Cosmos Health Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COST	Costco Wholesale Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
COYA	Coya Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPB	The Campbell's Company Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPBI	Central Plains Bancshares, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPHC	Canterbury Park Holding Corp. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPIX	Cumberland Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPOP	Pop Culture Group Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPRT	Copart, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPSH	CPS Technologies Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CPSS	Consumer Portfolio Services, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRAC	Crown Reserve Acquisition Corp. I	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRACR	Crown Reserve Acquisition Corp. I Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRAI	CRA International, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRAN	Crane Harbor Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRANR	Crane Harbor Acquisition Corp. II Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRAQ	Cal Redwood Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRAQR	Cal Redwood Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRBP	Corbus Pharmaceuticals Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRBU	Caribou Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRCT	Cricut Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRDF	Cardiff Oncology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRDL	Cardiol Therapeutics Inc. Class A Common Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRDO	Credo Technology Group Holding Ltd	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRE	Cre8 Enterprise Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRESY	Cresud S.A.C.I.F. y A. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CREX	Creative Realities Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRGO	Freightos Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRIS	Curis Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRKN	Crown Electrokinetics Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRMD	CorMedix Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRML	Critical Metals Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRMT	America's Car-Mart, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRNC	Cerence Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRNT	Ceragon Networks Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRNX	Crinetics Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRON	Cronos Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CROX	Crocs, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRSP	CRISPR Therapeutics AG	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRSR	Corsair Gaming, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRTO	Criteo S.A.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRUS	Cirrus Logic Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRVL	CorVel Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRVO	CervoMed Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRVS	Corvus Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRWD	CrowdStrike Holdings Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRWS	Crown Crafts Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CRWV	CoreWeave Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSAI	Cloudastructure Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSBR	Champions Oncology, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSCO	Cisco Systems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSGP	CoStar Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSHR	CoinShares PLC	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSIQ	Canadian Solar Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSLR	SunPower Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSPI	CSP Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSTE	Caesarstone Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSTL	Castle Biosciences Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSWC	Capital Southwest Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSWI	CSW Industrials Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CSX	CSX Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTAAR	ClearThink 1 Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTAS	Cintas Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTBI	Community Trust Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTCX	Carmell Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTKB	Cytek Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTMX	CytomX Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTNM	Contineum Therapeutics Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTNT	Cheetah Net Supply Chain Service Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTOR	Citius Oncology, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTRM	Castor Maritime Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTRN	Citi Trends Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTSH	Cognizant Technology Solutions Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTSO	CytoSorbents Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTW	CTW Cayman Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CTXR	Citius Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CUB	Lionheart Holdings Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CUE	Cue Biopharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CUEN	Cuentas Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CUPR	Cuprina Holdings (Cayman) Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CURI	CuriosityStream Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CURR	Currenc Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CURX	Curanex Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CUVL	Clinuvel Pharmaceuticals Limited	USD	NASDAQ	XNGS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
CV	CapsoVision, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVBF	CVB Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVCO	Cavco Industries Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVGI	Commercial Vehicle Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVKD	Cadrenal Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVLT	Commvault Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVRX	CVRx, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CVV	CVD Equipment Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CWBC	Community West Bancshares Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CWCO	Consolidated Water Co. Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CWD	CaliberCos Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CWST	Casella Waste Systems, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CXAI	CXApp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CXDO	Crexendo Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CXII	Churchill Capital Corp XII Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYAB	Cyabra Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYAN	Cyanotech Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYCC	Bio Green Med Solution, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYCN	Korsana Biosciences, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYCU	Cycurion Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYN	Cyngn Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYPH	Cypherpunk Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYRX	Cryoport Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CYTK	Cytokinetics, Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CZFS	Citizens Financial Services, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CZNC	Citizens & Northern Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CZR	Caesars Entertainment, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
CZWI	Citizens Community Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DAAQ	Digital Asset Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DAIC	CID HoldCo, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DAIO	Data I/O Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DAKT	Daktronics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DARE	Daré Bioscience, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DASH	DoorDash, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DATS	Myseum.AI, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DAVE	Dave Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DBCA	D. Boral Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DBGI	Digital Brands Group, Inc. Common Stock	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DBVT	DBV Technologies S.A. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
DBX	Dropbox Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCBO	Docebo Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCGO	DocGo Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCOM	Dime Commercial Bancshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCOMP	Dime Community Bancshares, Inc. 5.50% Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
DCOY	Decoy Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCTH	Delcath Systems, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DCX	Digital Currency X Technology Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DDI	DoubleDown Interactive Co., Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
DDOG	Datadog Inc. Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DEFT	DeFi Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DERM	Journey Medical Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DETX	Liberty Defense Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFDV	DeFi Development Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFLI	Dragonfly Energy Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFPH	DFP Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFSC	DEFSEC Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFSCW	DEFSEC Technologies Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DFTX	Definium Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGHI	Digi Power X Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGICA	Donegal Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGICB	Donegal Group Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGII	Digi International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGNX	Diginex Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DGXX	Digi Power X Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DH	Definitive Healthcare Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DHC	Diversified Healthcare Trust	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
DHCNI	Diversified Healthcare Trust 5.625% Senior Notes due 2042	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
DHCNL	Diversified Healthcare Trust 6.25% Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
DIBS	1stdibs.com Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DICE	DICE Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DIOD	Diodes Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DJCO	Daily Journal Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DJT	Trump Media & Technology Group Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DKI	DarkIris Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DKNG	DraftKings Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLHC	DLH Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLO	dLocal Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLPN	Dolphin Entertainment Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLTH	Duluth Holdings Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLTR	Dollar Tree Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DLXY	Delixy Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMAA	Drugs Made In America Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMAAR	Drugs Made In America Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMAC	DiaMedica Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMAQ	Deep Medicine Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMII	Drugs Made In America Acquisition II Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMIIR	Drugs Made In America Acquisition II Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMLP	Dorchester Minerals, L.P. Common Units	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
DMRA	Damora Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DMRC	Digimarc Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DNLI	Denali Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DNMX	Dynamix Corporation III Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DNTH	Dianthus Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DNUT	Krispy Kreme, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOCU	DocuSign Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOGZ	Dogness (International) Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOMH	Dominari Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOMO	Domo, Inc. Class B Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOOO	BRP Inc. Subordinate Voting Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DORM	Dorman Products, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOX	Amdocs Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DOYU	DouYu International Holdings Ltd. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
DPRO	Draganfly Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DPU	Top KingWin Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DPZ	Domino's Pizza, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRCT	Direct Digital Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRDB	Roman DBDR Acquisition Corp. II	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRIO	DarioHealth Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRMA	Dermata Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRS	Leonardo DRS Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRTS	Alpha Tau Medical Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRUG	Bright Minds Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DRVN	Driven Brands Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSAC	Daedalus Special Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSC	DSC Holdings Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
DSGN	Design Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSGR	Distribution Solutions Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSGX	The Descartes Systems Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSP	Viant Technology Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSWL	Deswell Industries Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DSY	Big Tree Cloud Holdings Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTCX	Datacentrex, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTI	Drilling Tools International Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTIL	Precision BioSciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTSQ	DT Cloud Star Acquisition Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTSQR	DT Cloud Star Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTSS	Datasea Intelligent Technology Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DTST	Data Storage Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DUKR	Duke Robotics Corp.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DUO	Fangdd Network Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DUOL	Duolingo, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DUOT	Duos Technologies Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DVLT	Datavault AI Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DWSN	Dawson Geophysical Company Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DWTX	Dogwood Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DXCM	DexCom Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DXLG	Destination XL Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DXPE	DXP Enterprises, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DXR	Daxor Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DXST	Decent Holding Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DYAI	Dyadic International, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DYN	Dyne Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
DYOR	Insight Digital Partners II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EAST	Eastside Distilling Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EBAY	eBay Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EBC	Eastern Bankshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EBMT	Eagle Bancorp Montana, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EBON	Ebang International Holdings Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ECBK	ECB Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ECHO	EchoStar Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ECOR	electroCore, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ECPG	Encore Capital Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ECX	ECARX Holdings Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDAP	Edap Tms S.A.	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
EDBL	Edible Garden AG Incorporated	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDHL	Everbright Digital Holding Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDIT	Editas Medicine, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDRY	EuroDry Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDSA	Edesa Biotech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDTK	Skillful Craftsman Education Technology Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EDUC	Educational Development Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EEFT	Euronet Worldwide Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EEIQ	EpicQuest Education Group International Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EFOI	Energy Focus Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EFSC	Enterprise Financial Services Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EFSCP	Enterprise Financial Services Corporation 5.00% Depositary Shares Non-Cumulative Perpetual Preferred Stock Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
EFSI	Eagle Financial Services Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EFTY	Etoiles Capital Group Co., Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EGAN	eGain Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EGBN	Eagle Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EGHA	EGH Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EGHAR	EGH Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EGHT	8x8 Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EH	EHang Holdings Limited Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
EHGO	Eshallgo Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EHLD	Euroholdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EHTH	eHealth, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EIKN	Eikon Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EJH	E-Home Household Service Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EKSO	Ekso Bionics Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELAB	PMGC Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELBM	Electra Battery Materials Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELDN	Eledon Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELE	Elemental Royalty Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELMT	Elmet Group Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELOG	Eastern International Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELOX	Eloxx Pharmaceuticals, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELPW	Elong Power Holding Limited Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELTK	Eltek Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELTX	Elicio Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELUT	Elutia Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELVA	Electrovaya Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELVN	Enliven Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELVR	Elevra Lithium Ltd ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ELWS	Earlyworks Co., Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ELWT	Elauwit Connection, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ELYS	ELYS Game Technology, Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EMAT	Evolution Metals & Technologies Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EMBC	Embecta Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EMISR	Emmis Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EML	The Eastern Company	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EMPD	Volcon, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENG	ENGlobal Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENGN	enGene Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENGS	Energys Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENLT	Enlight Renewable Energy Ltd. Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENLV	Enlivex Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENPH	Enphase Energy, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENRD	Einride AB American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ENSC	Ensysce Biosciences, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENSG	The Ensign Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENTA	Enanta Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENTG	Entegris Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENTX	Entera Bio Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENVB	Enveric Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ENVX	Enovix Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EOCN	Eocene Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EOLS	Evolus Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EOSE	Eos Energy Enterprises Inc. Ordinary Shares Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EPOW	E-Power Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EPRX	Eupraxia Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EPSM	Epsium Enterprise Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EPSN	Epsilon Energy Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EQ	Equillium Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EQIX	Equinix, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
EQPT	EquipmentShare.com Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ERAS	Erasca Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ERIC	Telefonaktiebolaget LM Ericsson Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ERIE	Erie Indemnity Company Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ERII	Energy Recovery, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ERNA	Ernexa Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESAC	Zeo Energy Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESCA	Escalade, Incorporated	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESEA	Euroseas Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESLA	Estrella Immunopharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESLT	Elbit Systems Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESOA	Energy Services of America Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESQ	Esquire Financial Holdings, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ESTA	Establishment Labs Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ETON	Eton Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ETOR	eToro Group Ltd. Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ETS	Elite Express Holding Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ETSY	Etsy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EU	enCore Energy Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EUDA	EUDA Health Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EURK	Eureka Acquisition Corp. Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EURKR	Eureka Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVAX	Evaxion A/S American Depositary Share	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
EVCM	EverCommerce Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVER	EverQuote Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVGN	Evogene Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVGO	EVgo Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVLO	Evelo Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVLV	Evolv Technologies Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVO	Evotec SE Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
EVOL	Symbolic Logic Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVOX	Evolution Global Acquisition Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVRG	Evergy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EVTV	Envirotech Vehicles Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EWAV	East West Ave Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EWAVR	East West Ave Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EWBC	East West Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EWTX	Edgewise Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXC	Exelon Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXE	Expand Energy Corp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXEL	Exelixis Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXFY	Expensify Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXLS	ExlService Holdings, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXOZ	eXoZymes Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXPE	Expedia Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXPI	AGNT, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXPO	Exponent Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXTR	Extreme Networks Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EXYN	Exyn Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EYE	National Vision Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EYEN	Hyperion DeFi Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EYES	Second Sight Medical Products Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EYPT	EyePoint, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EZFL	EzFill Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EZGO	EZGO Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EZPW	EZCORP, Inc. Class A Non-Voting Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
EZRA	Reliance Global Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FA	First Advantage Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FABC	Fabric.AI, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FAC	Factorial Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FACT	FACT II Acquisition Corp. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FAMI	Farmmi, Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FANG	Diamondback Energy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FANH	AIFU Inc. American Depositary Receipt	USD	NASDAQ	XNGS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FAST	Fastenal Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FATE	Fate Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FATN	FatPipe, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBDT	First Breach Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBGL	FBS Global Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBIO	Fortress Biotech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBIOP	Fortress Biotech Inc. Preferred Stock 9.375% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FBIZ	First Business Financial Services, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBLA	FB Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBLG	FibroBiologics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBNC	First Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBRX	Forte Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBYD	Falcon's Beyond Global, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FBYDP	Falcon's Beyond Global, Inc. - 8% Series A Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FCAP	First Capital Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCBC	First Community Bankshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCCO	First Community Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCEL	FuelCell Energy Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCFS	FirstCash Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCHL	Fitness Champs Holdings Limited Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCNCA	First Citizens BancShares, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FCNCN	First Citizens BancShares, Inc. 6.625% Non-Cumulative Perpetual Preferred Stock, Series E	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FCNCO	First Citizens BancShares, Inc. 5.625% Non-Cumulative Perpetual Preferred Stock, Series C	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FCNCP	First Citizens BancShares, Inc. 5.375% Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FCUV	Focus Universal Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FDBC	Fidelity D&D Bancorp, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FDMM	Freedom Metals Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FDMT	4D Molecular Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FDSB	Fifth District Bancorp, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FDUS	Fidus Investment Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FEAM	5E Advanced Materials Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FEBO	Fenbo Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FEED	ENvue Medical, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FEIM	Frequency Electronics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FELE	Franklin Electric Co., Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FEMY	Femasys Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FENC	Fennec Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FER	Ferrovial N.V.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FERA	Fifth Era Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FERAR	Fifth Era Acquisition Corp I Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFAI	Faraday Future Intelligent Electric Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFBC	First Financial Bancorp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFBW	FFBW Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFIE	Faraday Future Intelligent Electric Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFIN	First Financial Bankshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FFIV	F5, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGBI	First Guaranty Bancshares, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGBIP	First Guaranty Bancshares 6.75% Perpetual Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FGI	FGI Industries Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGII	FG Imperii Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGL	Founder Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGMC	Fg Merger Ii Corp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGNX	FG Nexus Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGNXP	Fundamental Global Inc. - 8.00% Cumulative Series A Preferred Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FGO	FG Holdings Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FHB	First Hawaiian, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FHTX	Foghorn Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIBK	First Interstate BancSystem, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIEE	FiEE, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIGR	Figure Technology Solutions, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIGX	FIGX Capital Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FINW	FinWise Bancorp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIP	FTAI Infrastructure Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FISI	Financial Institutions, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FISN	Deep Fission Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FISV	Fiserv, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FITB	Fifth Third Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FITBI	Fifth Third Bancorp 6.625% Fixed-to-Floating Rate Non-Cumulative Perpetual Preferred Stock Series I	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FIVE	Five Below, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIVN	Five9 Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIXX	Homology Medicines Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FIZZ	National Beverage Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FKWL	Franklin Wireless Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLAC	Frazier Lifesciences Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLD	Fold Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLEX	Flex Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLGC	Flora Growth Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLGT	Fulgent Genetics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLL	Full House Resorts Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLNA	Filana Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLNC	Fluence Energy, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLNT	Fluent Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLUX	Flux Power Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLWS	1-800-FLOWERS.COM, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLX	BingEx Limited American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FLXN	Flexion Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLXS	Flexsteel Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLY	Firefly Aerospace Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLYE	Fly-E Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLYW	Flywire Corp Voting Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FLZH	Flash Sports & Media Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMACR	Future Money Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMAO	Farmers & Merchants Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMBH	First Mid Bancshares Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMFC	Kandal M Venture Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMNB	Farmers National Banc Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FMST	Foremost Clean Energy Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNGR	FingerMotion Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNKO	Funko Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNLC	The First Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNRN	First Northern Community Bancorp	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNUC	Frontier Nuclear and Minerals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNWB	First Northwest Bancorp Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FNWD	Finward Bancorp Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FOCL	EDAP TMS S.A. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FOFO	Hang Feng Technology Innovation Co., Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FORD	Forward Industries Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FORM	FormFactor Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FORR	Forrester Research, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FORTY	Formula Systems (1985) Ltd. American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FOSL	Fossil Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FOX	Fox Corporation Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FOXA	Fox Corporation Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FOXF	Fox Factory Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FOXX	Foxx Development Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FPHOY	First Phosphate Corp. American Depositary Receipt	USD	NASDAQ	XNAS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FRAF	Franklin Financial Services Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRBA	First Bank	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRBT	Forbright, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRD	Friedman Industries, Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRGT	Freight Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRHC	Freedom Holding Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRME	First Merchants Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRMEP	First Merchants Corporation 7.50% Perpetual Preferred Stock Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FRMI	Fermi Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRMM	Forum Markets, Incorporated	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRNM	Freenome Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FROG	JFrog Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRPH	FRP Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRPT	Freshpet, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRSH	Freshworks Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRST	Primis Financial Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRSX	Foresight Autonomous Holdings Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FRTT	Fort Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FRVO	Fervo Energy Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSBC	Five Star Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSBW	FS Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSEA	First Seacoast Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSHP	Flag Ship Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSHPR	Flag Ship Acquisition Corp. Rights to receive one-tenth (1/10th) of one Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSLR	First Solar Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSTR	L.B. Foster Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSUN	FirstSun Capital Bancorp Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FSV	FirstService Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTAI	FTAI Aviation Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTAIM	FTAI Aviation Ltd. - 9.500% Fixed-Rate Reset Series D Cumulative Perpetual Redeemable Preferred Shares	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FTCI	FTC Solar Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTDR	Frontdoor Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTEK	Fuel Tech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTEL	GMEX Robotics Corporation Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTFT	Future FinTech Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTH	Faeth Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTHA	Forefront Tech Holdings Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTHM	Fathom Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTLF	FitLife Brands, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTNT	Fortinet, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTRE	Fortrea Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FTRK	Fast Track Group Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FUFU	BitFuFu Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FULC	Fulcrum Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FULT	Fulton Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FULTP	Fulton Financial Corporation 5.125% Fixed Rate Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
FUNC	First United Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FUSB	First US Bancshares, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FUTU	Futu Holdings Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
FVAV	Fortress Value Acquisition Corp. V Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FVCB	FVCBankcorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FVN	Future Vision II Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FVNNR	Future Vision II Acquisition Corp. Right	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWAC	Futurewave Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWACR	Futurewave Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWACW	Futurewave Acquisition Corporation Warrants	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWDI	Forward Industries Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWONA	Liberty Media Corporation Series A Liberty Formula One Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWONK	Liberty Media Corporation Series C Liberty Formula One Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWRD	Forward Air Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FWRG	First Watch Restaurant Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FXAC	FortuneX Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FXHO	UTime Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
FXNC	First National Corp. of Virginia	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GABC	German American Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAIA	Gaia, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAIN	Gladstone Investment Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAING	Gladstone Investment Corporation 7.125% Notes Due 2031	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GAINI	Gladstone Investment Corporation 7.875% Preferred Stock due 2030	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GAINZ	Gladstone Investment Corporation 4.875% Preferred Stock due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GALT	Galectin Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAMB	Gambling.com Group Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAME	GameSquare Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GANX	Gain Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GASS	StealthGas Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GAUZ	Gauzy Ltd. Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GBDC	Golub Capital BDC, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GBFH	GBank Financial Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCBC	Greene County Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCGR	General Catalyst Global Resilience Merger Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCL	GCL Global Holdings Ltd	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCMG	GCM Grosvenor Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCT	GigaCloud Technology Inc Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GCTK	GlucoTrack Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDC	GD Culture Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDEV	GDEV Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDHG	Golden Heaven Group Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDRX	GoodRx Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDS	GDS Holdings Limited ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GDTC	CytoMed Therapeutics Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GDYN	Grid Dynamics Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GECC	Great Elm Capital Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GECCG	Great Elm Capital Corp.	USD	NASDAQ	XNMS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
GECCH	Great Elm Capital Corp. Preferred Stock 8.125%	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GECCI	Great Elm Capital Corp Preferred Stock 8.5% 04/30/29	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GEG	Great Elm Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEGGL	Great Elm Group Inc. 7.25% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GEHC	GE HealthCare Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GELS	Gelteq Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEMI	Gemini Space Station, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEMQ	Goldman Sachs Data Enhanced Emerging Markets Equity ETF	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEN	Gen Digital Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GENB	Generate Biomedicines, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GENK	GEN Restaurant Group, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GENVR	Gen Digital Inc. Contingent Value Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEOS	Geospace Technologies Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GERN	Geron Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GEVO	Gevo Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GFAI	Guardforce AI Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GFS	GlobalFoundries Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GFUZ	General Fusion Group Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GGAL	Grupo Financiero Galicia S.A. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GGR	Gogoro Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GGRP	Glimpse Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GH	Guardant Health Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GHRS	GH Research PLC	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GHXI	Gores Holdings XI Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIAC	Gesher I Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIBO	GIBO Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIFT	Giftify Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIGM	GigaMedia Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIII	G-III Apparel Group, Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GILD	Gilead Sciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GILT	Gilat Satellite Networks Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIPR	Generation Income Properties Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GITS	Global Interactive Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIW	GigCapital8 Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIWWR	GigCapital8 Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIXI	Gix Internet Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GIXXR	GigCapital9 Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLAD	Gladstone Capital Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLBE	Global-E Online Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLBS	Globus Maritime Limited Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLE	Global Engine Group Holding Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLIBA	Liberty Capital Corporation Series A GCI Group Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLIBK	Liberty Capital Corporation Series C GCI Group Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLMD	Eocene Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLND	Greenland Energy Company Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLNG	Golar LNG Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLOO	Gloo Holdings Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLPG	Galapagos NV American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GLPI	Gaming and Leisure Properties, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
GLRE	Greenlight Capital Re, Ltd. Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLSI	Greenwich LifeSciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLTO	Damora Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLUE	Monte Rosa Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLXG	Galaxy Payroll Group Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLXY	Galaxy Digital Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GLYC	Crescent Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GMAB	Genmab A/S American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GMBLP	Esports Entertainment Group, Inc.	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GMEX	GMEX Robotics Corporation Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GMHS	Gamehaus Holdings Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GMM	Global Mofy AI Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GMTX	Gemini Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNLN	Greenlane Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNLX	Genelux Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNMX	Aevi Genomic Medicine Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNPX	Genprex Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNSS	Genasys Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GNTA	Genenta Science S.p.A. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GNTX	Gentex Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GO	Grocery Outlet Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOAI	Eva Live Inc. Common Stock	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GODN	Golden Star Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOGL	Golden Ocean Group Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOGO	Gogo Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOOD	Gladstone Commercial Corporation	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
GOODN	Gladstone Commercial Corporation 6.625% Series E Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GOODO	Gladstone Commercial Corporation 6% Series G Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GOOG	Alphabet Inc. Class C Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOOGL	Alphabet Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOOGM	Alphabet Inc.	USD	NASDAQ	XNGS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GOOGN	Alphabet Inc. 6.25% Series A Mandatory Convertible Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GOSS	Gossamer Bio, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GOVX	GeoVax Labs, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GP	GreenPower Motor Company Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPAC	General Purpose Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPACW	Global Partner Acquisition Corp II	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPAT	GP-Act III Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPCO	Golden Path Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPCR	Structure Therapeutics Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GPRE	Green Plains Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GPRO	GoPro Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRAB	Grab Holdings Ltd. Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRAL	GRAIL, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRAN	Grande Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRCE	Grace Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRDX	GridAI Technologies Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GREEL	Greenidge Generation Holdings Inc. 8.50% Senior Notes due 2026	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
GRFS	Grifols S.A. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GRI	GRI Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRIN	Grindrod Shipping Holdings Ltd	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRML	Greenland Mines Ltd	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRNQ	Greenpro Capital Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GROW	U.S. Global Investors Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRPN	Groupon, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRRR	Gorilla Technology Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRSD	Grandstand Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRVI	Grove, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GRVY	Gravity Co., Ltd. Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
GRWG	GrowGeneration Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSAT	Globalstar Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSBC	Great Southern Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSHD	Goosehead Insurance Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSHR	Gesher Acquisition Corp. II-A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSIT	GSI Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSIW	Garden Stage Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSM	Ferroglobe PLC	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSRF	GSR IV Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSRFR	GSR IV Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSRV	GSR V Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSRVR	GSR V Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GSUN	Golden Sun Technology Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GT	The Goodyear Tire & Rubber Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTBP	GT Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTEC	Greenland Technologies Holding Corp. Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTEN	Gores Holdings X Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTERA	Globa Terra Acquisition Corp Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTERR	Globa Terra Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTI	Graphjet Technology	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTIM	Good Times Restaurants Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTLB	GitLab Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTM	ZoomInfo Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GTX	Garrett Motion Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GUAC	Berto Acquisition Corp. II	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GURE	Gulf Resources, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GUTS	Fractyl Health, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GV	Visionary Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GVH	Globavend Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GWAV	Greenwave Technology Solutions, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GWRS	Global Water Resources, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GXAI	Gaxos.ai Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GYGY	Game Your Game Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GYRE	Gyre Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
GYRO	Gyrodyne LLC	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HACQ	HCM IV Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAFC	Hanmi Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAIN	The Hain Celestial Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HALL	Hallmark Financial Services, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HALO	Halozyme Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAO	Haoxi Health Technology Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAPN	Happen, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAS	Hasbro, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAVA	Harvard Ave Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HAVAR	Harvard Ave Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBAN	Huntington Bancshares Incorporated Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBANL	Huntington Bancshares Incorporated - Depositary Shares, Each Representing a 1/40th Interest in a Share of 6.875% Series J Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HBANM	Huntington Bancshares Incorporated 5.70% Series I Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HBANP	Huntington Bancshares Incorporated 4.5% Series H Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HBANZ	Huntington Bancshares Incorporated 5.500% Perpetual Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HBCP	Home Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBIO	Harvard Bioscience Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBNB	Hotel101 Global Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBNC	Horizon Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HBT	HBT Financial, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCAC	Hennessy Capital Acquisition Corp IV	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCACR	Hall Chadwick Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCAI	Huachen AI Parking Management Technology Holding Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCAT	Health Catalyst, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCHL	Happy City Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCIC	Hennessy Capital Investment Corp. V	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCICR	Hennessy Capital Investment Corp. VIII Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCICU	Hennessy Capital Investment Corp. V	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
HCKT	The Hackett Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCM	HUTCHMED (China) Limited ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HCMA	HCM III Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCSG	Healthcare Services Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCTI	Healthcare Triangle Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HCWB	HCW Biologics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HDL	Super Hi International Holding Ltd. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HDRN	Hadron Energy, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HDSN	Hudson Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HELE	Helen of Troy Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HELP	Cybin Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HEPA	Hepion Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HEPS	D-Market Electronic Services & Trading ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HERE	Here Group Limited American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HFBL	Home Federal Bancorp, Inc. of Louisiana	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HFFG	HF Foods Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HFWA	Heritage Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HGBL	Heritage Global Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HHS	Harte Hanks Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HIFS	Hingham Institution for Savings	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HIHO	Highway Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HIMX	Himax Technologies Inc. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HIND	ReShape Lifesciences, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HIT	Health In Tech Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HITI	High Tide Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HIVE	HIVE Digital Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HJLI	Hancock Jaffe Laboratories Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HKIT	Hitek Global Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HKPD	Cellyan Biotechnology Co., Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLIT	Harmonic Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLMN	Hillman Solutions Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLNE	Hamilton Lane Inc. Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLP	Hongli Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLTH	Nobilis Health Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HLXC	Helix Acquisition Corp. III Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HMH	HMH Holding Inc. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HMR	Heidmar Maritime Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HMST	Mechanics Bancorp Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HNNA	Hennessy Advisors, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HNRG	Hallador Energy Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HNST	The Honest Company, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HNVR	Hanover Bancorp, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HODO	House of Doge Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOFT	Hooker Furnishings Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOLO	MicroCloud Hologram Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HON	Honeywell International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HONA	Honeywell Aerospace Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOOD	Robinhood Markets Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOPE	Hope Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOTH	Hoth Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOUR	Hour Loop, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOVNP	Hovnanian Enterprises, Inc. Preferred Stock 7.625% Perpetual	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HOVR	New Horizon Aircraft Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HOWL	Werewolf Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HPAI	Helport AI Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HPK	HighPeak Energy, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HQ	Horizon Quantum Holdings Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HQI	HireQuest Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HQY	HealthEquity, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HRMY	Harmony Biosciences Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HROW	Harrow Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HRTX	Heron Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HRYU	Global Interactive Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HRZN	Horizon Technology Finance Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HSAI	Hesai Group American Depositary Share	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HSAQ	Health Sciences Acquisitions Corporation 2	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HSCS	HeartSciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HSDT	Solana Company Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HSIC	Henry Schein, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HST	Host Hotels & Resorts, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
HSTM	HealthStream Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTBI	HomeTrust Bancshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTCO	High-Trend International Group Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTCR	HeartCore Enterprises, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTFL	HeartFlow Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTHT	H World Group Limited ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HTIA	Healthcare Trust Inc	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HTIBP	Healthcare Trust, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTLD	Heartland Express, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTLM	HomesToLife Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTO	H2O America	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTOO	Fusion Fuel Green PLC Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HTZ	Hertz Global Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUBC	Hub Cyber Security Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUBG	Hub Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUDI	Huadi International Group Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUHU	HUHUTECH International Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUIZ	Huize Holding Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
HUMA	Humacyte Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HURA	TuHURA Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HURC	Hurco Companies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HURN	Huron Consulting Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUSN	Hudson Capital Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HUT	Hut 8 Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HVII	Hennessy Capital Investment Corp. VII	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HVIIR	Hennessy Capital Investment Corp. VII Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HVMC	Highview Merger Corp. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HWBK	Hawthorn Bancshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HWC	Hancock Whitney Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HWCPZ	Hancock Whitney Corporation 6.25% Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
HWH	HWH International Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HWKN	Hawkins, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HXHX	Haoxin Holdings Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYFM	Hydrofarm Holdings Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYFT	ImmunoPrecise Antibodies Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYMC	Hycroft Mining Holding Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYNE	Hoyne Bancorp, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYPD	Hyperion DeFi Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
HYPR	Hyperfine, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IA	Innovative Solutions & Support Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IAC	People Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IACO	Idea Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IACQ	Irenic Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IART	Integra LifeSciences Holdings Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBAC	IB Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBACR	IB Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBCP	Independent Bank Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBEX	IBEX Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBG	Innovation Beverage Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBIO	iBio, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBKR	Interactive Brokers Group, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBOC	International Bancshares Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IBRX	ImmunityBio Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICCC	ImmuCell Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICCM	IceCure Medical Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICFI	ICF International, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICG	Intchains Group Limited American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ICHR	Ichor Holdings, Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICLK	Amber International Holding Ltd. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ICLR	ICON plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICMB	Investcorp Credit Management BDC, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICON	Icon Energy Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICU	SeaStar Medical Holding Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ICUI	ICU Medical, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDAC	Iron Dome Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDAI	T Stamp Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDCC	InterDigital Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDN	Intellicheck Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDXX	IDEXX Laboratories, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IDYA	IDEAYA Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IEAG	Infinite Eagle Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IEAGR	Infinite Eagle Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IEP	Icahn Enterprises L.P. Depositary Units Representing Limited Partner Interests	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
IESC	IES Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IFBD	Infobird Co. Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IFRX	InflaRx N.V.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IGAC	Invest Green Acquisition Corporation Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IGACR	Invest Green Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IGIC	International General Insurance Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IHRT	iHeartMedia Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
III	Information Services Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IIIV	i3 Verticals Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IINN	Inspira Technologies Oxy B.H.N. Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IKNA	ImageneBio Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IKT	Inhibikase Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ILAG	Intelligent Living Application Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ILLR	Triller Group Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ILLU	Illumination Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ILMN	Illumina Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ILPT	Industrial Logistics Properties Trust	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
IMA	ImageneBio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMAB	I-Mab Sponsored ADR	USD	NASDAQ	XNMS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IMCC	IM Cannabis Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMCR	Immunocore Holdings plc ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IMDX	Insight Molecular Diagnostics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMKTA	Ingles Markets Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMMP	Immutep Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IMMR	Immersion Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMMX	Immix Biopharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMNM	Immunome, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMNN	Imunon Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMOS	ChipMOS Technologies Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IMPP	Imperial Petroleum Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMPPP	Imperial Petroleum Inc. 8.75% Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
IMRN	Immuron Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IMRX	Immuneering Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMSR	Terrestrial Energy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMSRW	HCM II Acquisition Corp. Warrant	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMTE	Integrated Media Technology Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMTX	Immatics N.V.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMUX	Immunic, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMVT	Immunovant Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IMXI	International Money Express, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INAB	IN8bio, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INAC	Indigo Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INACR	Indigo Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INAQ	Alpha Modus Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INBK	First Internet Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INBKZ	First Internet Bancorp 4.29% Preferred Stock due 2029	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
INBS	Intelligent Bio Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INBX	Inhibrx Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INCR	InterCure Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INCY	Incyte Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INDB	Independent Bank Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INDI	indie Semiconductor, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INDP	Indaptus Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INDV	Indivior Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INEO	INNEOVA Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INGN	Inogen Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INHD	Inno Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INIO	Innio N.V.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INKT	MiNK Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INLF	Inlif Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INM	InMed Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INMB	INmune Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INMD	InMode Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INNV	InnovAge Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INO	Inovio Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INOD	Innodata Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INPX	Inpixon	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INSE	Inspired Entertainment, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INSG	Inseego Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INSM	Insmed Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTA	Intapp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTC	Intel Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTG	The InterGroup Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTJ	Intelligent Group Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTR	Inter & Co. Inc. Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTS	Intensity Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTU	Intuit Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INTZ	Intrusion Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INV	Innventure, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INVA	Innoviva Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INVE	Identiv Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INVO	Naya Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
INVZ	Innoviz Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IOND	Ionic Digital Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IONR	Ioneer Ltd ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IONS	Ionis Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IOSP	Innospec Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IOTR	iOThree Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IOVA	Iovance Biotherapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPA	MindWalk Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPAR	Interparfums, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPDN	Professional Diversity Network, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPEX	Inflection Point Acquisition Corp. V Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPEXR	Inflection Point Acquisition Corp. V Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPFX	Inflection Point Acquisition Corp. VI Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPGP	IPG Photonics Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPHA	Innate Pharma S.A. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IPIC	IPIC Entertainment Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPM	Intelligent Protection Management Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPSC	Century Therapeutics Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPST	Heritage Distilling Holding Company, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPVV	InterPrivate Investment Partners V, Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPW	iPower Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPWR	Ideal Power Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPX	IperionX Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IPXG	Inflection Point Acquisition Corp. VII	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IPXX	USA Rare Earth, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IQ	iQIYI, Inc. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IQMX	IQM Quantum Computers Oyj American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IQST	iQSTEL Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRD	Opus Genetics, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRDM	Iridium Communications Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IREN	IREN Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRHO	Iron Horse Acquisitions Corp. II Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRHOR	Iron Horse Acquisitions Corp. II Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRIX	Iridex Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRMD	iRadimed Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRON	Disc Medicine, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRTC	iRhythm Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IRWD	Ironwood Pharmaceuticals, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISBA	Isabella Bank Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISNR	Snow Rothschild Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISPC	iSpecimen Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISPR	Ispire Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISRG	Intuitive Surgical Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISSC	Innovative Solutions & Support Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ISTR	Investar Holding Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITG	ITG, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITHA	ITHAX Acquisition Corp III	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITIC	Investors Title Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITOC	iTonic Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITRI	Itron, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ITRN	Ituran Location and Control Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IVA	Inventiva S.A. American Depositary Receipt	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
IVCP	Swiftmerge Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IVDA	Iveda Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IVF	INVO Fertility Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IVVD	Invivyd, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IXHL	Incannex Healthcare Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IZEA	IZEA Worldwide, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
IZM	ICZOOM Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JAB	JAB Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JABRR	JAB Acquisition Corp I Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JACK	Jack in the Box Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JAGX	Jaguar Health, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JAKK	JAKKS Pacific, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JAN	JanOne Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JANX	Janux Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JATT	JATT II Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JAZZ	Jazz Pharmaceuticals plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JBDI	JBDI Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JBHT	J.B. Hunt Transport Services, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JBIO	Jade Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JBLU	JetBlue Airways Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JBSS	John B. Sanfilippo & Son, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JCAP	Jefferson Capital Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JCIC	Jack Creek Investment Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JCSE	JE Cleantech Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JCTC	Jewett-Cameron Trading Company Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JCTCF	Jewett-Cameron Trading Company Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JD	JD.com, Inc. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JDZG	Jiade Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JEM	707 Cayman Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JF	J and Friends Holdings Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JFB	JFB Construction Holdings Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JFIN	Jiayin Group Inc. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JFU	9F Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JG	Aurora Mobile Limited ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JJSF	J&J Snack Foods Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JKHY	Jack Henry & Associates, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JL	J-Long Group Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JLHL	Julong Holding Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JMSB	John Marshall Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JONE	Jones Ventures INTL Acquisition1 Corp Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JONER	Jones Ventures INTL Acquisition1 Corp Share Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JOUT	Johnson Outdoors Inc. Class A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JOYY	JOYY Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JRSH	Jerash Holdings (US), Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JRVR	James River Group Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JSM	Navient Corporation 6% Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
JSPR	Jasper Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JTAI	Jet.AI Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JTTT	JATT III Acquisition Corp Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JUNS	Jupiter Neurosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JVA	Coffee Holding Co., Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JWEL	Jowell Global Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JXG	JX Luxventure Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JYD	Jayud Global Logistics Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JYNT	The Joint Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
JZ	Jianzhi Education Technology Group Company Limited ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
JZXN	Jiuzi Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KA	Kineta, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KALA	KALA BIO, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KALU	Kaiser Aluminum Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KARD	Kardigan Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KARO	Karooooo Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KAZR	Skyline Builders Group Holding Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KBNT	Kubient Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KBON	Karbon Capital Partners Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KBSX	FST Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KC	Kingsoft Cloud Holdings Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
KCHV	Kochav Defense Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KCHVR	Kochav Defense Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KDK	Kodiak AI Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KDP	Keurig Dr Pepper Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KE	Kimball Electronics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KEEL	Keel Infrastructure Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KELYA	Kelly Services Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KELYB	Kelly Services Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KEQU	Kewaunee Scientific Corporation Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KERN	Akerna Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KEYY	Keystone Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KFFB	Kentucky First Federal Bancorp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KFII	K&F Growth Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KFIIR	K&F Growth Acquisition Corp. II Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KG	Kestrel Group Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KGEI	Kolibri Global Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KHC	The Kraft Heinz Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KIDS	OrthoPediatrics Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KIDZ	KIDZ AI Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KINS	Kingstone Companies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KITT	Nauticus Robotics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLAC	KLA Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLDO	Kaleido Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLIC	Kulicke & Soffa Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLRA	Kailera Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLRS	Kalaris Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLTR	Kaltura Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLXE	KLX Energy Services Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KLXER	KLX Energy Services Holdings, Inc. Right	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KMB	Kimberly-Clark Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KMDA	Kamada Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KMRK	K-Tech Solutions Company Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KMTS	Kestra Medical Technologies, Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KNDI	Kandi Technologies Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KNSA	Kiniksa Pharmaceuticals International, plc Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KOD	Kodiak Sciences Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KOPN	Kopin Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KOSS	Koss Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCID	Lucid Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KOYN	CSLM Digital Asset Acquisition Corp III, Ltd Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KPLT	Katapult Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KPRX	Kiora Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KPTI	Karyopharm Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRAQ	KRAKacquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRKR	36Kr Holdings Inc. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
KRMD	KORU Medical Systems Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRNT	Kornit Digital Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRNY	Kearny Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KROS	Keros Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRRO	Korro Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRSA	Korsana Biosciences, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRT	Karat Packaging Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRUS	Kura Sushi USA, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KRYS	Krystal Biotech, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KSCP	Knightscope Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KSPI	Kaspi.kz JSC ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
KTCC	Key Tronic Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KTOS	Kratos Defense & Security Solutions, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KTRA	Tuhura Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KTTA	Pasithea Therapeutics Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KTWO	K2 Capital Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KTWOR	K2 Capital Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KURA	Kura Oncology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KUST	Kustom Entertainment Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KVHI	KVH Industries Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KWM	K Wave Media Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KXIN	Kaixin Holdings	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KYIV	Kyivstar Group Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KYMR	Kymera Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KYNB	Kyntra Bio, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KYTX	Kyverna Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
KZIA	Kazia Therapeutics Ltd Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LAB	Standard BioTools Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LABT	Lakewood-Amedex Biotherapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAES	SEALSQ Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAFA	LaFayette Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAFAR	LaFayette Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAKE	Lakeland Industries, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAMR	Lamar Advertising Company Class A	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
LANC	The Marzetti Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAND	Gladstone Land Corporation	USD	NASDAQ	XNMS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
LANDO	Gladstone Land Corporation Preferred Stock 6% Perpetual	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
LANDP	Gladstone Land Corp	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
LARK	Landmark Bancorp, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LASE	Laser Photonics Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LASR	nLIGHT, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LATA	Galata Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAUR	Laureate Education, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAWR	Robot Consulting Co., Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LAWS	Lawson Products Inc-DE	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAX	8i Acquisition 2 Corp. Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LAZR	Luminar Technologies, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBGJ	Li Bang International Corporation Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBRDA	Liberty Broadband Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBRDK	Liberty Broadband Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBRDP	Liberty Broadband Corporation 7.00% Series A Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
LBRX	LB Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBTYA	Liberty Global Ltd. Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBTYB	Liberty Global Ltd. Class B Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LBTYK	Liberty Global Ltd. Class C Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCCC	Lakeshore Acquisition III Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCCCR	Lakeshore Acquisition III Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCFY	Locafy Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCNB	LCNB Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LCUT	Lifetime Brands Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LDWY	Lendway Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LE	Lands' End Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LECO	Lincoln Electric Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LEDS	SemiLEDs Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LEE	Lee Enterprises, Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LEGH	Legacy Housing Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LEGN	Legend Biotech Corporation ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LEGO	Legato Merger Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LENZ	LENZ Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LESL	Leslie's Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LEXX	Lexaria Bioscience Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFAC	Leapfrog Acquisition Corporation Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFCR	Lifecore Biomedical Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFMD	LifeMD, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFMDP	LifeMD Inc. 8.875% Perpetual Preferred Stock Series A	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
LFS	Leifras Co., Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LFST	LifeStance Health Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFTO	Liftoff Mobile, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFUS	Littelfuse Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFVN	LifeVantage Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LFWD	Lifeward Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGCL	Lucas GC Limited Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGHL	Lion Group Holding Ltd. American Depositary Share	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LGIH	LGI Homes, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGN	Legence Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGND	Ligand Pharmaceuticals Incorporated	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGO	Largo Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGST	Semper Paratus Acquisition Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LGVN	Longeveron Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LHAI	Linkhome Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LHSW	Lianhe Sowell International Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LI	Li Auto Inc. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LIAN	LianBio	USD	NASDAQ	XNMS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LICN	Lichen International Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIDR	AEye, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIEN	Chicago Atlantic BDC, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIF	Life360, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIFE	Ethos Technologies Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LILA	Liberty Latin America Ltd. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LILAK	Liberty Latin America Ltd. Class C Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LILAP	Liberty Latin America Ltd. 9.0% Fixed Rate Cumulative Perpetual Redeemable Series A Preference Shares	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
LIME	Neutron Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIMN	Liminatus Pharma, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIN	Linde plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LINC	Lincoln Educational Services Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIND	Lindblad Expeditions Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LINE	Lineage, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
LINK	Interlink Electronics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIQT	LiqTech International Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LITE	Lumentum Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LITM	Frontier Nuclear and Minerals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LITS	MEI Pharma, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIVE	Live Ventures Incorporated	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIVN	LivaNova PLC	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LIXT	Lixte Biotechnology Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LJAQ	LightJump Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LKFN	Lakeland Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LKFT	Lakefront Biotherapeutics American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LKQ	LKQ Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LKSP	Lake Superior Acquisition Corp. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LKSPR	Lake Superior Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LLYVA	Liberty Live Holdings, Inc. Series A Liberty Live Group Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LLYVK	Liberty Live Holdings, Inc. Series C Liberty Live Group Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMAT	LeMaitre Vascular Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMB	Limbach Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMFA	Lm Funding America Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMNR	Limoneira Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMNX	Luminex Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMPX	LMP Automotive Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LMRI	Lumexa Imaging Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNAI	Lunai Bioworks Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNDC	Landec Corp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNKS	Linkers Industries Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNSR	LENSAR Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNT	Alliant Energy Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNTH	Lantheus Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LNZA	LanzaTech Global Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOAN	Manhattan Bridge Capital, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
LOBO	Lobo Technologies Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOCO	El Pollo Loco Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOGI	Logitech International S.A.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LONA	LeonaBio, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOOP	Loop Industries, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOPE	Grand Canyon Education Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LOT	Lotus Technology Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LOVE	The Lovesac Company	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPAA	Launch One Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPBB	Launch Two Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPCN	Lipocine Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPCV	Launchpad Cadenza Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPLA	LPL Financial Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPSN	LivePerson Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPTH	LightPath Technologies Inc Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LPTX	Cypherpunk Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LQDA	Liquidia Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LQDT	Liquidity Services Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LQR	Lqr House Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LRCX	Lam Research Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LRE	Lead Real Estate Co., Ltd American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LRHC	La Rosa Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LRMR	Larimar Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSAK	Lesaka Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSBK	Lake Shore Bancorp, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSCC	Lattice Semiconductor Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSE	Leishen Energy Holding Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSTA	Lisata Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LSTR	Landstar System, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTBR	Lightbridge Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTCH	Latch, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTGO	Latigo Biotherapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTGR	Long Table Growth Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTRN	Lantern Pharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LTRX	Lantronix, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LUCD	Lucid Diagnostics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LUCY	Lucyd, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LULU	lululemon athletica inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LUNG	Pulmonx Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LUNR	Intuitive Machines, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LVLU	Lulu's Fashion Lounge Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LVO	LiveOne Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LWAC	LightWave Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LWAY	Lifeway Foods, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LWLG	Lightwave Logic, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LX	LexinFintech Holdings Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LXEH	Lixiang Education Holding Co., Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
LXEO	Lexeo Therapeutics, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LXRX	Lexicon Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LYEL	Lyell Immunopharma, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LYFT	Lyft, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LYL	Dragon Victory International Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LYT	Lytus Technologies Holdings PTV. Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LYTS	LSI Industries Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LZ	LegalZoom.com, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
LZMH	LZ Technology Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAAQ	Mana Capital Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAAS	Maase Inc. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MACI	Melar Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAGH	Magnitude International Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAKO	Mako Mining Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAMA	Mama's Creations, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAMK	MaxsMaking Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAMO	Massimo Group	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MANH	Manhattan Associates Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAR	Marriott International, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MARA	MARA Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MARK	Remark Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MARPS	Marine Petroleum Trust Units of Beneficial Interest	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
MARX	ScanTech AI Systems Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MASK	3 E Network Technology Group Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MASS	908 Devices Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAT	Mattel Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MATH	Metalpha Technology Holding Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MATW	Matthews International Corp Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAXN	Maxeon Solar Technologies Ltd	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAYS	J.W. Mays, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MAZE	Maze Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MB	MasterBeef Group Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBAI	Check-Cap Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBBC	Marathon Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBIN	Merchants Bancorp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBINL	Merchants Bancorp 7.625% Perpetual Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MBINM	Merchants Bancorp Preferred Stock Series 8.25% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MBINN	Merchants Bancorp 6% Perpetual Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MBIO	Mustang Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBLY	Mobileye Global Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBNKO	Medallion Bank Utah 9% Perpetual Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MBOT	Microbot Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBRX	Moleculin Biotech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBUU	Malibu Boats Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBVI	M3-Brigade Acquisition VI Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBWM	Mercantile Bank Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MBX	MBX Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCAH	Mountain Crest Acquisition 6 Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCAHR	Mountain Crest Acquisition 6 Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCBS	MetroCity Bankshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCFT	MasterCraft Boat Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCGA	Yorkville Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCHP	Microchip Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCHPP	MICROCHIP TECHNOLOGY DEP SHS REPSTG 1/20TH PFD CONV SER A	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCHX	Marchex Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCOM	Micromobility.com Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCRB	Seres Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCRI	Monarch Casino & Resort, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCTA	Charming Medical Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MCVT	Sui Group Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDAI	Spectral AI Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDB	MongoDB, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDBH	MDB Capital Holdings LLC Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDCX	Medicus Pharma Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDGL	Madrigal Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDIA	MediaCo Holding Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDJH	Mdjm Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDLN	Medline Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDLZ	Mondelēz International, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDNAF	Medicenna Therapeutics Corp.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDRR	Medalist Diversified, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
MDRX	Veradigm Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDWD	MediWound Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDXG	MiMedx Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MDXH	MDxHealth SA	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ME	23andMe Holding Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MEDP	Medpace Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MEDS	DataMeds AI Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MEGL	Magic Empire Global Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MELI	MercadoLibre Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MENS	Jyong Biotech Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MEOH	Methanex Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MERC	Mercer International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MESA	Republic Airways Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MESH	Meshflow Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MESO	Mesoblast Ltd Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
META	Meta Platforms Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
METC	Ramaco Resources Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
METCB	Ramaco Resources Inc. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
METCI	Ramaco Resources, Inc. 8.25% Preferred Stock due July 31, 2030	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
METCZ	Ramaco Resources, Inc. 8.375% Preferred Stock due 2029	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MEVO	M Evo Global Acquisition Corp II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MF	MindForge Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MFI	mF International Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MFIC	MidCap Financial Investment Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MFICL	MidCap Financial Investment Corporation 8.00% Notes due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MFIN	Medallion Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MFP	Midera Food Processing, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGEE	MGE Energy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGIH	Millennium Group International Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGN	Megan Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGNI	Magnite, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGNX	MacroGenics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGPI	MGP Ingredients Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGRC	McGrath RentCorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGRT	Mega Fortune Company Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGRX	Mangoceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGTX	MeiraGTx Holdings plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGX	Metagenomi Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MGYR	Magyar Bancorp, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MHLD	Maiden Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIAC	Meridian3 Industrials Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MICS	Algorhythm Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIDD	The Middleby Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIGI	Mawson Infrastructure Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIMI	Mint Incorporation Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIND	MIND Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIRA	Mira Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIRM	Mirum Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MIST	Milestone Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MITC	Steakholder Foods Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MITK	Mitek Systems Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKDW	MKDWELL Tech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKLY	McKinley Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKLYR	McKinley Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKSI	MKS Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKTW	MarketWise Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKTX	MarketAxess Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MKZR	MacKenzie Realty Capital, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
MLAA	Mountain Lake Acquisition Corp. II	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLAB	Mesa Laboratories, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLAC	Mountain Lake Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLCI	Mount Logan Capital Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLCIL	Mount Logan Capital Inc. 8.00% Series A Preferred Stock due 1/31/2031	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MLCO	Melco Resorts & Entertainment Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MLEC	Moolec Science SA	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLGO	MicroAlgo Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLKN	MillerKnoll Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLTX	MoonLake Immunotherapeutics Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MLYS	Mineralys Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MMED	MiniMed Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MMLP	Martin Midstream Partners L.P.	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
MMSI	Merit Medical Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MMTX	Miluna Acquisition Corp Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MMV	MultiMetaVerse Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MMYT	MakeMyTrip Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNDO	Mind C.T.I. Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNDR	Mobile-health Network Solutions Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNDY	monday.com Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNKD	MannKind Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNMD	Definium Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNOV	MediciNova Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNPR	Monopar Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNRO	Monro, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNSB	MainStreet Bancshares Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNSBP	MainStreet Bancshares Inc. 7.5% Perpetual Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MNST	Monster Beverage Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNTK	Montauk Renewables Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNTS	Momentus Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MNY	MoneyHero Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOB	Mobilicom Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOBI	Mobia Medical, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOBQ	Mobiquity Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOBX	Mobix Labs, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MODD	Modular Medical, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOGO	Orion Digital Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOLN	Molecular Partners AG ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MOMO	Hello Group Inc. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MORN	Morningstar Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOTS	Motus GI Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MOVE	Corvex Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MPAA	Motorcar Parts of America, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MPB	Mid Penn Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MPLT	MapLight Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MPWR	Monolithic Power Systems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MQ	Marqeta Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRAM	Everspin Technologies, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRBK	Meridian Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRCO	Mercator Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRCY	Mercury Systems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRDN	Golden Matrix Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MREO	Mereo BioPharma Group plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MRKR	Marker Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRLN	Merlin, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRM	MEDIROM Healthcare Technologies Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MRNA	Moderna Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRNO	Murano Global Investments Plc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRTN	Marten Transport, Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRVI	Maravai LifeSciences Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRVL	Marvell Technology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MRX	Marex Group plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSAI	MultiSensor AI Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSBI	Midland States Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSBIP	Midland States Bancorp, Inc. 7.75% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
MSEX	Middlesex Water Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSFT	Microsoft Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSGM	Motorsport Games Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSGY	Masonglory Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSLE	Satellos Bioscience Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSS	Maison Solutions Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MSTR	Strategy Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTBC	MTBC Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTC	MMTec Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTCH	Match Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTEK	Maris-Tech Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTEN	Mingteng International Corporation Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTEX	Mannatech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTLS	Materialise NV ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MTP	Midatech Pharma PLC	USD	NASDAQ	XNCM	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MTRX	Matrix Service Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTSI	MACOM Technology Solutions Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MTVA	MetaVia Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MU	Micron Technology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MULN	Mullen Automotive, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MUZE	Muzero Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MVBF	MVB Financial Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MVIS	MicroVision, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MVLA	Movella Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MVST	Microvast Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MWC	Micware Co., Ltd. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
MWH	SOLV Energy, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MWYN	Marwynn Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MXCT	MaxCyte, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MXL	MaxLinear, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYFW	First Western Financial, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYGN	Myriad Genetics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYNZ	Quantum Cyber N.V.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYPS	PLAYSTUDIOS, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYRG	MYR Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYSE	Myseum, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYSZ	My Size, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYX	Maywood Acquisition Corp. 2 Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MYXXR	Maywood Acquisition Corp. 2 Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
MZTI	The Marzetti Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NA	Nano Labs Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAAS	NaaS Technology Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NAGE	Niagen Bioscience Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAII	Natural Alternatives International, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAKA	Kindly MD, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAMI	Jinxin Technology Holding Company ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NAMM	Namib Minerals	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAMS	NewAmsterdam Pharma Company N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAOV	Envue Medical, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NATH	Nathan's Famous Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NATR	Nature's Sunshine Products, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAUT	Nautilus Biotechnology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAVI	Navient Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NAVN	Navan, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NB	NioCorp Developments Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBBK	NB Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBIS	Nebius Group N.V. Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBIX	Neurocrine Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBN	Northeast Bank	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBP	NovaBridge Biosciences American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NBRG	Newbridge Acquisition Limited Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBRGR	Newbridge Acquisition Limited Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBTB	NBT Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NBTX	Nanobiotix S.A. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NCEL	NewcelX Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCEW	New Century Logistics (BVI) Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCI	Neo-Concept International Group Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCMI	National CineMedia, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCNA	NuCana plc ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NCNC	noco-noco Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCNO	nCino, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCO	Southern Cross Acquisition I Corp. Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCOOR	Southern Cross Acquisition I Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCPL	Netcapital Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCRA	Nocera, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCSM	NCS Multistage Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCT	Intercont (Cayman) Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NCTY	The9 Ltd. Sponsored American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NDAQ	Nasdaq, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NDLS	Noodles & Company Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NDRA	ENDRA Life Sciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NDSN	Nordson Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NECB	NorthEast Community Bancorp, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEGG	Newegg Commerce Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEO	NeoGenomics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEOG	Neogen Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEON	Neonode Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEOV	NeoVolta Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEPH	Nephros Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NERV	Minerva Neurosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NESR	National Energy Services Reunited Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NETE	Net Element Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEUP	Neuphoria Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEWT	NewtekOne, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEWTG	NewtekOne Inc. 8.5% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NEWTH	NewtekOne Inc. 8.625% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NEWTI	NewtekOne, Inc. - 8.00% Fixed Rate Senior Notes due 2028	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NEWTO	NewtekOne Inc. 8.500% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series B	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NEWTP	NewtekOne, Inc. 8.500% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NEXM	NexMetals Mining Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEXN	Nexxen International Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEXR	Nexera Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NEXT	NextDecade Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NFE	New Fortress Energy Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NFLX	Netflix Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NGEN	NervGen Pharma Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NGNE	Neurogene Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NHIC	NewHold Investment Corp III Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NHIV	NewHold Investment Corp IV Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NHP	National Healthcare Properties, Inc.	USD	NASDAQ	XNMS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
NHPAP	National HealthCare Properties Inc. 7.375% Perpetual Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NHPBP	National Healthcare Properties Inc. Preferred Stock 7.125% Callable Perpetual	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NHTC	Natural Health Trends Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NICE	NICE Ltd. Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NICK	Old Market Capital Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NICM	Nicola Mining Inc. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NIKI	Niki BioSolutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NIPG	NIP Group Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NIU	Niu Technologies Sponsored ADR Class A	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NIVF	NewGenIvf Group Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	Thailand	Common Stock	2026-09-14 21:16:47.001842+00	\N
NIXX	Nixxy, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKGN	Nkgen Biotech Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKLA	Nikola Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKLR	Terra Innovatum Global N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKSH	National Bankshares Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKTR	Nektar Therapeutics	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NKTX	Nkarta, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NLSP	NLS Pharmaceutics Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMAD	Nomad Power Solutions, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMFC	New Mountain Finance Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMFCZ	New Mountain Finance Corporation Preferred Stock 8.25%	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NMIH	NMI Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMP	NMP Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMPAR	NMP Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMRA	Neumora Therapeutics, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMRD	Nemaura Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMRK	Newmark Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NMTC	NeuroOne Medical Technologies Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NN	NextNav Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NNBR	NN, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NNDM	Nano Dimension Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NNE	Nano Nuclear Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NNNN	Anbio Biotechnology Ltd	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NNOX	Nano-X Imaging Ltd. Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NODK	NI Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NOEM	CO2 Energy Transition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NOEMR	CO2 Energy Transition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NOMA	Nomadar Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NOVT	Novanta Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NOVTU	Novanta Inc. 6.50% Tangible Equity Units due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NOVV	Nova Vision Acquisition Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NPAC	New Providence Acquisition Corp. III Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NPCE	NeuroPace, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NPT	Texxon Holding Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRC	NRC Health	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRDS	NerdWallet Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRIM	Northrim Bancorp, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRIX	Nurix Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRRWF	NuRAN Wireless Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRSN	NeuroSense Therapeutics Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NRXP	NRx Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSAI	NorthStrive Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSAIR	NorthStrive Acquisition Corp I. Right	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSIT	Insight Enterprises, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSLR	Neostellar Capital Corp. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSLRL	Neostellar Capital Corp.	USD	NASDAQ	XNMS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
NSPR	InspireMD, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSSC	Napco Security Technologies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSTS	NSTS Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NSYS	Nortech Systems Incorporated	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTAP	NetApp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTCL	NetClass Technology Inc Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTCT	NetScout Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTES	NetEase, Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NTGR	NETGEAR Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTHI	NeOnc Technologies Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTIC	Northern Technologies International Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTLA	Intellia Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTNX	Nutanix, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTRA	Natera, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTRB	Nutriband Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTRP	NextTrip Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTRS	Northern Trust Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTRSO	Northern Trust Corporation 4.70% Non-Cumulative Perpetual Preferred Stock, Series E	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NTSK	Netskope Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTWK	NetSol Technologies, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NTWO	Newbury Street II Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUAI	New Era Energy & Digital Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUAIW	New Era Helium Inc Warrants	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUCL	EAGLE NUCLEAR ENERGY CORP	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUCLW	Eagle Nuclear Energy Corp. Warrants	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUR	NuRAN Wireless Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUTX	Nutex Health Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUVOW	Holdco Nuvo Group D.G Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUWE	Nuwellis, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NUZE	Cimg Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVA	Nova Minerals Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NVAX	Novavax Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVCR	NovoCure Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVCT	Nuvectis Pharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVDA	NVIDIA Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVEC	NVE Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVFY	XMax Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVMI	Nova Ltd. Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVNI	Nvni Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVNO	enVVeno Medical Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVTS	Navitas Semiconductor Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NVX	Novonix Ltd. Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NWBI	Northwest Bancshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWE	NorthWestern Energy Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWFL	Norwood Financial Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWGL	CL Workshop Group Limited American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
NWL	Newell Brands Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWPX	NWPX Infrastructure Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWS	News Corp Class B	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWSA	News Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NWTG	Newton Golf Company Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXAT	Nexus Advanced Technologies Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXGL	NexGel Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXH	Neighborhood Intelligence, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXL	Nexalin Technology, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXPI	NXP Semiconductors N.V.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXPL	NextPlat Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXST	Nexstar Media Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXT	Nextpower Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXTC	NextCure, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXTP	NextPlay Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXTS	N2OFF, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXTT	Next Technology Holding Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXU	Nxu, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NXXT	NextNRG, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NYAX	Nayax Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NYMT	Adamas Trust Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
NYMTL	New York Mortgage Trust, Inc. 6.875% Series F Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NYMTM	New York Mortgage Trust, Inc. 7.875% Series E Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NYMTN	New York Mortgage Trust, Inc. 8.00% Series D Fixed-to-Floating Rate Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NYMTZ	New York Mortgage Trust, Inc. 7.00% Series G Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
NYNY	Empire Resorts, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
NYXH	Nyxoah SA	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OABI	OmniAb, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OACC	Oaktree Acquisition Corp. III Life Sciences Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OAS	Oasis Petroleum Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OB	Teads Holding Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OBA	Oxley Bridge Acquisition Ltd Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OBAI	Our Bond, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OBIO	Orchestra BioMed Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OBT	Orange County Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OBX	Obsidian Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCC	Optical Cable Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCCIM	OFS Credit Company Inc.	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OCCIN	OFS Credit Company Preferred Stock 5.25%	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OCEA	Ocean Biomedical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCFC	OceanFirst Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCG	Oriental Culture Holding Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCGN	Ocugen Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCLT	OceanLight Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPRT	Oportun Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCLTR	OceanLight Acquisition Corporation Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCS	Oculis Holding AG	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCSL	Oaktree Specialty Lending Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCTO	Eightco Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCTV	Octave Intelligence plc Class B Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCUL	Ocular Therapeutix, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCUP	Opus Genetics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OCX	Insight Molecular Diagnostics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ODD	Oddity Tech Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ODFL	Old Dominion Freight Line, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ODTX	Odyssey Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ODYS	Odysight.ai Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OESX	Orion Energy Systems, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFAL	OFA Group Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFED	Oconee Federal Financial Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFIX	Orthofix Medical Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFLX	Omega Flex Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFS	OFS Capital Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OFSSH	OFS Capital Corporation 4.95% Notes due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OFSSO	OFS Capital Corporation 7.50% Series Preferred Stock due July 31, 2028	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OGI	Organigram Global Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OHAC	Oceanhawk Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OHACR	Oceanhawk Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OIM	OneIM Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OIO	OIO Group Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OKTA	Okta Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OKUR	OnKure Therapeutics, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OKYO	OKYO Pharma Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OLB	The OLB Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OLED	Universal Display Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OLLI	Ollie's Bargain Outlet Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OLMA	Olema Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OLOX	Olenox Industries Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OM	Outset Medical, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMAB	Grupo Aeroportuario del Centro Norte S.A.B. de C.V. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
OMCL	Omnicell, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMDA	Omada Health, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMER	Omeros Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMEX	Odyssey Marine Exploration, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMH	Ohmyhome Ltd. Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OMSE	OMS Energy Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ON	ON Semiconductor Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONB	Old National Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONBPO	Old National Bancorp 7.00% Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ONBPP	Old National Bancorp 7.00% Non-Cumulative Perpetual Preferred Stock, Series A	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ONC	BeOne Medicines Ltd. American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ONCH	1RT Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONCO	Onconetix Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONCY	Oncolytics Biotech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONDS	Ondas Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONEG	OneConstruction Group Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONEW	OneWater Marine Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONFO	Onfolio Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONMD	OneMedNet Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONTX	Onconova Therapeutics Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ONVO	VivoSim Labs Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OP	OceanPal Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPAL	OPAL Fuels Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPBK	OP Bancorp Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPCH	Option Care Health Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPEN	Opendoor Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPI	Office Properties Income Trust	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
OPK	OPKO Health, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPRA	Opera Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
OPRX	OptimizeRx Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPTH	Optimi Health Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPTX	Syntec Optics Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OPXS	Optex Systems Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORBS	Eightco Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORGO	Organogenesis Holdings Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORIC	Oric Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORIO	Orion Digital Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORIQ	Origin Investment Corp I Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORIS	Oriental Rise Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORKA	Oruka Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORKT	Orangekloud Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORLY	O'Reilly Automotive Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORMP	Oramed Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ORRF	Orrstown Financial Services, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSBC	Old Second Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSIS	OSI Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSPN	OneSpan Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSPR	Osprey Acquisition Corp. III Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSRH	OSR Health, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSS	One Stop Systems Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OST	Ostin Technology Group Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSTK	Overstock.com Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSUR	OraSure Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OSW	OneSpaWorld Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OTEX	Open Text Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OTGA	OTG Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OTLK	Outlook Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OTLY	Oatly Group AB ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
OTTR	Otter Tail Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OUST	Ouster Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OVBC	Ohio Valley Banc Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OVID	Ovid Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OVLY	Oak Valley Bancorp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OWLS	OBOOK Holdings Inc. Class A Common Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OXBR	Oxbridge Re Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OXLCG	Oxford Lane Capital Corp. 7.95% Notes due 2032	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCI	Oxford Lane Capital Corp. 8.75% Notes due 2030	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCL	Oxford Lane Capital Corp. 6.75% Notes due 2031	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCM	Oxford Lane Capital Corp	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCN	Oxford Lane Capital Corp. 7.125% Series 2029 Term Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCO	Oxford Lane Capital Corp. 6.00% Series 2029 Term Preferred Shares	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCP	Oxford Lane Capital Corp. 6.25% Series 2027 Term Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXLCZ	Oxford Lane Capital Corp. 5.00% Term Preferred Stock due 2027	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXSQ	Oxford Square Capital Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OXSQG	Oxford Square Capital Corp. 5.5% Notes due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OXSQH	Oxford Square Capital Corp. 7.75% Notes Due 2030	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
OYSE	Oyster Enterprises II Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OYSER	Oyster Enterprises II Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OZK	Bank OZK	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
OZKAP	Bank OZK 4.625% Series A Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
PAA	Plains All American Pipeline, L.P. Common Units	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
PAAC	Proficient Alpha Acquisition Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAACU	Proficient Alpha Acquisition Corp	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
PACB	Pacific Biosciences of California, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PACH	Pioneer Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAFO	Pacifico Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAGP	Plains GP Holdings, L.P. Class A Shares	USD	NASDAQ	XNGS	United States	Limited Partnership	2026-09-14 21:16:47.001842+00	\N
PAHC	Phibro Animal Health Corporation Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAL	Proficient Auto Logistics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PALI	Palisade Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PALO	Paloma Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAMT	PAMT Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PANL	Pangaea Logistics Solutions Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PANW	Palo Alto Networks Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PARA	Paramount Global	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PARK	Park Dental Partners Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PASG	Passage Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PASW	Ping An Biomedical Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PATK	Patrick Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAVM	Pavmed Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAVS	Paranovus Entertainment Technology Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAX	Patria Investments Limited Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAYO	Payoneer Global Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAYP	PayPay Corp ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PAYS	Paysign Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PAYX	Paychex Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBAM	Private Bancorp of America, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBAX	Phoenix Biotech Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBFS	Pioneer Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBHC	Pathfinder Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBK	PowerBank Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBLS	Parabilis Medicines, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBM	Psyence Biomedical Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBNC	PB Financial Corporation	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PBYI	Puma Biotechnology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PC	Premium Catering Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCAP	ProCap Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCAR	PACCAR Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCB	PCB Bancorp Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCLA	PicoCELA Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PCRX	Pacira BioSciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCSA	Processa Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCT	PureCycle Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCTY	Paylocity Holding Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCVX	Vaxcyte Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCYG	Park City Group Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PCYO	Pure Cycle Corporation Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PDC	Perpetuals.com Ltd. Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PDD	PDD Holdings Inc. American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PDEX	Pro-Dex Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PDFS	PDF Solutions, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PDLB	Ponce Financial Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PDSB	PDS Biotechnology Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PDYN	Palladyne AI Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PEBK	Peoples Bancorp of North Carolina, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PEBO	Peoples Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PECE	Peace Acquisition Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PECER	Peace Acquisition Corp Right	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PECO	Phillips Edison & Company, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
PEGA	Pegasystems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PENG	Penguin Solutions Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PENN	PENN Entertainment, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PEP	PepsiCo, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PEPG	PepGen Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PERI	Perion Network Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PESI	Perma-Fix Environmental Services, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PET	Wag! Group Co.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PETS	PetMed Express Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PETV	Petvivo Holdings Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PETZ	TDH Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PEV	Phoenix Motor Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFAI	Pinnacle Food Group Limited Class A Common Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFBC	Preferred Bank	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFG	Principal Financial Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFHC	ProFrac Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFIS	Peoples Financial Services Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFSA	Profusa Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFX	PhenixFIN Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PFXNZ	PhenixFIN Corp. Preferred Stock 5.25% Callable 2028	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
PGAC	Pantages Capital Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PGACR	Pantages Capital Acquisition Corporation Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PGC	Peapack-Gladstone Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PGEN	Precigen Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PGNY	Progyny Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PGY	Pagaya Technologies Ltd. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PHAR	Pharming Group N.V. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PHAT	Phathom Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PHIO	Phio Pharmaceuticals Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PHOE	Phoenix Asia Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PHUN	Phunware, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PHVS	Pharvaris N.V. Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PI	Impinj Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PICS	PicS N.V. Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PIII	P3 Health Partners Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PIK	Kidpik Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PINC	Premier Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PIRS	Palvella Therapeutics Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PITA	Heramba Electric plc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PKBK	Parke Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PKOH	Park-Ohio Holdings Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLAB	Photronics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLAY	Dave & Buster's Entertainment, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLBC	Plumas Bancorp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLBL	Polibeli Group Ltd Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLBY	Playboy, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLCE	The Children's Place, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLCI	Pelican Acquisition II Corp. Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLCIR	Pelican Acquisition II Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLMK	Plum Acquisition Corp. IV Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLMR	Palomar Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLPC	Preformed Line Products Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLRX	Pliant Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLRZ	Polyrizon Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLSE	Pulse Biosciences Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLSM	Pulsenmore Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLTK	Playtika Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLTR	Palantir Technologies Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLTS	Platinum Analytics Cayman Limited	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLUG	Plug Power Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLUR	Pluri Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLUS	ePlus Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLUT	Plutus Financial Group Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLXS	Plexus Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PLYX	Polaryx Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMA	Ming Shing Group Holdings Limited Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMAX	Powell Max Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMCB	PharmaCyte Biotech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMD	Psychemedics Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMEC	Primech Holdings Ltd. Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMN	ProMIS Neurosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMTR	Perimeter Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMTS	CPI Card Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PMVP	PMV Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PN	PN Smart Energy Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PNBK	Patriot National Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PNFP	Pinnacle Financial Partners Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PNRG	PrimeEnergy Resources Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PNTG	The Pennant Group Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POAI	Axe Compute Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POCI	Precision Optics Corporation, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PODC	PodcastOne, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PODD	Insulet Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POET	POET Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POLA	Polar Power, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POLE	Andretti Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POM	PomDoctor Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PONO	Pono Capital Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PONOR	Pono Capital Four Inc. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PONOU	Pono Capital Corp.	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
PONY	Pony AI Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
POOL	Pool Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POWI	Power Integrations, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POWL	Powell Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POWW	Outdoor Holding Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
POWWP	Ammo Inc. Preferred Stock 8.75% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
PPBT	Purple Biotech Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PPC	Pilgrim's Pride Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPCB	Propanc Biopharma, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPHC	Public Policy Holding Company, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPIH	Perma-Pipe International Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPLI	People Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPSI	Pioneer Power Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PPTA	Perpetua Resources Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRAA	PRA Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRAX	Praxis Precision Medicines, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRCH	Porch Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRCT	PROCEPT BioRobotics Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRDO	Perdoceo Education Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRE	Prenetics Global Limited Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRFX	PRF Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRGS	Progress Software Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRHI	Presurance Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRHIZ	Presurance Holdings, Inc. 9.75% Preferred Stock due 2028	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
PRLD	Prelude Therapeutics Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRME	Prime Medicine, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PROC	Procaps Group S.A.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PROF	Profound Medical Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PROK	ProKidney Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PROP	Prairie Operating Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PROV	Provident Financial Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRPL	Purple Innovation Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRPO	Precipio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRQR	ProQR Therapeutics N.V. Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRSO	Peraso Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRTA	Prothena Corp PLC	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRTC	PureTech Health plc - ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PRTG	Alpha Compute Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRTH	Priority Technology Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRTO	Proteon Therapeutics Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRTS	CarParts.com, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRVA	Privia Health Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PRZO	ParaZero Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PS	Pluralsight Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSEC	Prospect Capital Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSHG	Performance Shipping Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSIG	PS International Group Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSIX	Power Solutions International, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSKY	Paramount Skydance Corporation Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSMT	PriceSmart, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSNL	Personalis Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PSNY	Polestar Automotive Holding UK PLC Class A ADS	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PSQL	Pasqal Holding SA	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTAC	PropTech Acquisition Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTACU	PropTech Acquisition Corp	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
PTC	PTC Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTCT	PTC Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTEN	Patterson-UTI Energy, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTGX	Protagonist Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTLE	PTL Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTLO	Portillo's Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTMN	BCP Investment Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTON	Peloton Interactive Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTOR	Praetorian Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTRN	Pattern Group Inc. Series A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PTSI	Pamt Corp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PUBM	PubMatic Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PULM	Pulmatrix Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PURR	Hyperliquid Strategies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PUSA	Aureus Greenway Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PUYI	Puyi Inc	USD	NASDAQ	XNMS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
PVLA	Palvella Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PWCM	PowerCompute Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PWP	Perella Weinberg Partners Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PXLW	Pixelworks, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PXMD	PaxMedica Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PXS	Pyxis Tankers Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PYPD	PolyPid Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PYPL	PayPal Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PYXS	Pyxis Oncology, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
PZZA	Papa John's International, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QADR	QDRO Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QCLS	Q/C Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QCOM	QUALCOMM Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QCRH	QCR Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QDEL	QuidelOrtho Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QDROU	Quadro Acquisition One Corp. - Unit	USD	NASDAQ	XNCM	United States	Unit	2026-09-14 21:16:47.001842+00	\N
QETA	Quetta Acquisition Corp. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QETAR	Quetta Acquisition Corporation Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QFIN	Qfin Holdings Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
QH	Quhuo Limited	USD	NASDAQ	XNMS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
QLYS	Qualys, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QMCO	Quantum Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QMLS	QumulusAI, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNBC	QNB Corp.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNCX	Quince Therapeutics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNME	Quanome Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNRX	Quoin Pharmaceuticals, Ltd. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
QNST	QuinStreet, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNT	Quantinuum Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QNTM	Quantum BioPharma Ltd. Class B Subordinate Voting Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QRHC	Quest Resource Holding Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QRVO	Qorvo Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QSEA	Quartzsea Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QSEAR	Quartzsea Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QSI	Quantum-Si Incorporated Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QTEX	QTREX Quantum Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QTI	QT Imaging Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QTRX	Quanterix Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QTTB	Q32 Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QUBT	Quantum Computing Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QUCY	Quantum Cyber N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QUIK	QuickLogic Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QUMS	Quantumsphere Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QUMSR	Quantumsphere Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QURE	uniQure N.V.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QVC	QVC Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QVCG	QVC Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
QXL	Quantum X Labs Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RACC	Research Alliance Corporation III Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RACD	Research Alliance Corporation IV Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RADX	Radiopharm Theranostics Limited Depositary Receipt	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
RAIL	FreightCar America Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAIN	Rain Enhancement Technologies Holdco, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAM	Aries I Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAND	Rand Capital Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RANG	Range Capital Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RANGR	Range Capital Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RANI	Rani Therapeutics Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAPP	Rapport Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RARE	Ultragenyx Pharmaceutical Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAVE	Rave Restaurant Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAY	Atlas Trinity Tech Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RAYA	Erayak Power Solution Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBB	RBB Bancorp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBBN	Ribbon Communications Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBCAA	Republic Bancorp, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBCN	Rubicon Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBKB	Rhinebeck Bancorp, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBNE	Robin Energy Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RBNEV	Robin Energy Ltd. Common Stock When Issued	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCAT	Red Cat Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCBC	River City Bank	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCEL	Avita Medical, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCKT	Rocket Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCKY	Rocky Brands, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCMT	RCM Technologies Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCON	Recon Technology, Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCRT	Nixxy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RCT	RedCloud Holdings plc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDAC	Rising Dragon Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDACR	Rising Dragon Acquisition Corp. Rights	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDAG	Republic Digital Acquisition Company Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDCM	Radcom Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDGT	Ridgetech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDHL	RedHill Biopharma Ltd. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
RDI	Reading International Inc. Class A Non-Voting Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDIB	Reading International Inc. Class B Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDNT	RadNet Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDNW	RideNow Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDVT	Red Violet, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDWR	Radware Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RDZN	Roadzen Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REAL	The RealReal, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REAX	Real Brokerage Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REBN	Reborn Coffee, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RECT	Rectitude Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REFI	Chicago Atlantic Real Estate Finance, Inc.	USD	NASDAQ	XNMS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
REFR	Research Frontiers Incorporated	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REG	Regency Centers Corporation	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
REGCO	Regency Centers Corporation - 5.875% Series B Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
REGCP	Regency Centers Corporation - 6.25% Series A Cumulative Redeemable Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
REGN	Regeneron Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REKR	Rekor Systems, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RELI	Reliance Global Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RELL	Richardson Electronics, Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RELY	Remitly Global, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RENB	Lunai Bioworks Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RENT	Rent the Runway, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RENX	RenX Enterprises Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REPL	Replimune Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RETO	ReTo Eco-Solutions Inc. Class A Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REVB	Revelation Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
REYN	Reynolds Consumer Products Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RFAI	RF Acquisition Corp. II Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RFAIR	RF Acquisition Corp II Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RFAM	RF Acquisition Corp III Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RFAMR	RF Acquisition Corp III Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RFIL	RF Industries, Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGC	Regencell Bioscience Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGCO	RGC Resources Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGEN	Repligen Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGF	The Real Good Food Company, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGLD	Royal Gold, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGNX	Regenxbio Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGP	Resources Connection, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGS	Regis Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RGTI	Rigetti Computing, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RHLD	Resolute Holdings Management, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIBB	Ribbon Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIBBR	Ribbon Acquisition Corp Right	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIBT	RiceBran Technologies	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RICK	RCI Hospitality Holdings, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIGL	Rigel Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RILY	BRC Group Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RILYG	B. Riley Financial Inc., Series 5 Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RILYL	B. Riley Financial Inc. 7.375% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RILYN	B. Riley Financial Inc. 6.5% Preferred Stock due 09/30/26	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RILYP	B. Riley Financial Inc. Preferred Stock 6.875% Perpetual	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RILYT	B. Riley Financial Inc. 6% Preferred Stock Due 2028	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RILYZ	B. Riley Financial Inc. Preferred Stock 5.25% 08/31/28	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RIME	Algorhythm Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIOT	Riot Platforms, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RITR	Reitar Logtech Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RIVN	Rivian Automotive Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RJET	Republic Airways Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RKDA	Arcadia Biosciences Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RKLB	Rocket Lab Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RKTO	Rocket One Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RLAY	Relay Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RLMD	Relmada Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RLYB	Rallybio Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMBI	Richmond Mutual Bancorporation, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMBL	RideNow Group, Inc. Class B Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMBS	Rambus Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMCF	Rocky Mountain Chocolate Factory, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMCO	Royalty Management Holding Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMIX	Suncrete Inc Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RML	Resolution Minerals Ltd. Sponsored ADR	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMNI	Rimini Street, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMR	The RMR Group Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMSG	Real Messenger Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RMTI	Rockwell Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNA	Atrium Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNAC	Cartesian Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNAZ	TransCode Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNBW	Rainbow Capital Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNGT	Range Capital Acquisition Corp II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNTX	Rein Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNW	ReNew Energy Global Plc Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RNXT	RenovoRx, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROAD	Construction Partners, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROC	Rank One Computing Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROCK	Gibraltar Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROCL	Roth CH Acquisition V Co.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROII	Riskon International Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROIV	Roivant Sciences Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROKU	Roku, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROLL	iShares Bloomberg Roll Select Commodity Swap UCITS ETF	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROMA	Roma Green Finance Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROOT	Root Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROP	Roper Technologies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ROST	Ross Stores Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RPAY	Repay Holdings Corporation Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RPD	Rapid7, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RPGL	Republic Power Group Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RPID	Rapid Micro Biosystems Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RPRX	Royalty Pharma plc Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RR	Richtech Robotics Inc. Class B Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RRBI	Red River Bancshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RREV	RRE Ventures Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RRGB	Red Robin Gourmet Burgers Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RRR	Red Rock Resorts, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RSLS	Vyome Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RSMIY	Resolution Minerals Ltd. American Depositary Shares	USD	NASDAQ	XNAS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
RSSS	Research Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RSVR	Reservoir Media Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RTAC	Renatus Tactical Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RTB	RTB Digital Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RTC	Baijiayun Group Ltd	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RUBI	Rubico Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RUM	RUM Group Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RUN	Sunrun Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RUSHA	Rush Enterprises, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RUSHB	Rush Enterprises Inc. Class B	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RVMD	Revolution Medicines, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RVSB	Riverview Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RVSN	Rail Vision Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RWAY	Runway Growth Finance Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RWAYI	Runway Growth Finance Corp. 7.25% Notes due 2031	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RWAYL	Runway Growth Finance Corp. 7.50% Preferred Stock due 2027	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
RXRX	Recursion Pharmaceuticals, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RXST	RxSight, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RXT	Rackspace Technology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RYAAY	Ryanair Holdings plc Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
RYET	Ruanyun Edai Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RYM	Agrify Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RYOJ	rYojbaba Co., Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RYTM	Rhythm Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RZLT	Rezolute Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
RZLV	Rezolve AI PLC	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAAQ	Space Asset Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SABR	Sabre Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SABS	SAB Biotherapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAFT	Safety Insurance Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAFX	XCF Global, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAGT	Sagtec Global Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAIA	Saia Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAIC	Science Applications International Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAIH	SAIHEAT Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAIL	SailPoint, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SALM	Salem Media Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAMG	Silvercrest Asset Management Group Inc. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SANA	Sana Biotechnology Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SANG	Sangoma Technologies Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SANM	Sanmina Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SATA	Strive Inc. Variable Rate Series A Perpetual Preferred Stock (SATA), 12% Initial Annual Dividend	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SATL	Satellogic Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SATS	EchoStar Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SAVA	Filana Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBAC	SBA Communications Corporation	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SBC	SBC Medical Group Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBCF	Seacoast Banking Corporation of Florida	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBET	Sharplink Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBFG	SB Financial Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBFM	Sunshine Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBGI	Sinclair, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBLK	Star Bulk Carriers Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBNY	Signature Bank	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SBRA	Sabra Health Care REIT, Inc.	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SBUX	Starbucks Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCAG	Scage Future American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SCHL	Scholastic Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCII	SC II Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCIIR	SC II Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCKT	Socket Mobile Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCLX	Scilex Holding Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCNI	Scinai Immunotherapeutics Ltd. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SCNX	Scienture Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCOR	comScore, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCPQ	Social Commerce Partners Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCPS	Scopus Biopharma Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCSC	ScanSource, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCTX	Scribe Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCVL	Shoe Station Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCWO	374Water Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCYX	SCYNEXIS, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SCZM	Santacruz Silver Mining Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDA	SunCar Technology Group Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDGR	Schrödinger, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDHI	Siddhi Acquisition Corp Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDHIR	Siddhi Acquisition Corp Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDOT	Sadot Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SDST	Stardust Power Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEAT	Vivid Seats Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEDG	SolarEdge Technologies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEED	Origin Agritech Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEER	Seer, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEGG	Sports Entertainment Gaming Global Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEIC	SEI Investments Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SELF	Global Self Storage, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SENEA	Seneca Foods Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SENEB	Seneca Foods Corp. Class B Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEPN	Septerna, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SERA	Sera Prognostics, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SERV	Serve Robotics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SEVN	Seven Hills Realty Trust	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SEZL	Sezzle Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFBC	Sound Financial Bancorp, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFD	Smithfield Foods, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFET	Safe-T Group Ltd	USD	NASDAQ	XNCM	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SFHG	Samfine Creation Holdings Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFIX	Stitch Fix, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFM	Sprouts Farmers Market Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFNC	Simmons First National Corporation Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFST	Southern First Bancshares, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SFWL	Shengfeng Development Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGA	Saga Communications, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGBX	Safe & Green Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGC	Superior Group of Companies, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGHT	Sight Sciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGLD	Scorpio Gold Corp. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SGLY	Singularity Future Technology Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGML	Sigma Lithium Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGMS	Scientific Games Corp	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGMT	Sagimet Biosciences Inc. Series A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGP	SpyGlass Pharma Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGRX	Sangrix Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SGRY	Surgery Partners Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHAZ	SharonAI Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHBI	Shore Bancshares, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHC	Sotera Health Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHEN	Shenandoah Telecommunications Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHFS	SHF Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHIM	Shimmick Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHIP	Seanergy Maritime Holdings Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHLS	Shoals Technologies Group Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHMD	Schmid Group N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHOE	Shoe Station Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHOO	Steven Madden Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHOP	Shopify Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHOT	Safety Shot Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHOTR	RMG ML Sports Holdings Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SHPH	Shuttle Pharmaceuticals Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIBN	SI-BONE, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIC	Select Interior Concepts Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIDU	Sidus Space, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIEB	Siebert Financial Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIFY	Sify Technologies Limited Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SIGA	SIGA Technologies Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIGI	Selective Insurance Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIGIP	Selective Insurance Group, Inc. 4.60% Depositary Shares Non-Cumulative Preferred Stock Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SILC	Silicom Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SILO	Silo Pharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIMA	SIM Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIMO	Silicon Motion Technology Corp. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SINT	SINTX Technologies, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SION	Sionna Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SIRI	Sirius XM Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SITM	SiTime Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SJ	Scienjoy Holding Corporation Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKHY	SK hynix Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SKIN	SkinHealth Systems Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKK	SKK Holdings Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKWD	Skyward Specialty Insurance Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKYA	SkyAI Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKYE	Skye Bioscience Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKYQ	Sky Quarry Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKYW	SkyWest Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SKYX	SKYX Platforms Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLAB	Silicon Laboratories Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLBT	SL Science Holding Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLCR	Silver Crest Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLDB	Solid Biosciences Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLDE	Slide Insurance Holdings, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLDP	Solid Power, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLE	Super League Enterprise Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLGB	Smart Logistics Global Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLGL	Sol-Gel Technologies Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLM	SLM Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLMBP	SLM Corporation Floating Rate Non-Cumulative Preferred Stock Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SLMT	Solmate Infrastructure Public Limited Company Class B Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLN	Silence Therapeutics Plc ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SLNG	Stabilis Solutions Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLNH	Soluna Holdings, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLNHP	Soluna Holdings Inc. 9% Perpetual Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SLP	Simulations Plus Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLRC	SLR Investment Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLS	SELLAS Life Sciences Group, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLSN	Solesence Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SLXN	Silexion Therapeutics Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMBC	Southern Missouri Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMCI	Super Micro Computer Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMCIP	Super Micro Computer, Inc. 7.00% Mandatory Convertible Preferred Stock due 2029	USD	NASDAQ	XNAS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SMFR	Sema4 Holdings Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMID	Smith-Midland Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMIT	Schmitt Industries Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMMT	Summit Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMPL	The Simply Good Foods Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMSI	Smith Micro Software Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMTC	Semtech Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMTI	Sanara MedTech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMTK	SmartKem, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMX	SMX (Security Matters) Public Limited Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SMXT	SolarMax Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNAL	Snail Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNAX	Stryve Foods Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SND	Smart Sand, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNDK	Sandisk Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNDL	SNDL Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNDX	Syndax Pharmaceuticals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNES	SenesTech, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNEX	StoneX Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNFCA	Security National Financial Corporation Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNGX	Soligenix Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNOA	Sonoma Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNPS	Synopsys Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNPX	TAO Synergies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNSE	Faeth Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNT	Senstar Technologies Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNTG	Sentage Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNTI	Senti Biosciences Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNWV	SANUWAVE Health, Inc. Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SNY	Sanofi ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SNYR	Synergy CHC Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOBR	SOBR Safe, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOCA	Solarius Capital Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOFI	SoFi Technologies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOFO	Sonic Foundry Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOGP	Sound Group Inc. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SOHOB	Sotherly Hotels Inc. 8% Preferred Stock	USD	NASDAQ	XNAS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SOHON	Sotherly Hotels Preferred Stock 8.25% Perpetual	USD	NASDAQ	XNAS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SOHOO	Sotherly Hotels Inc. 7.875% Preferred Stock	USD	NASDAQ	XNAS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SOHU	Sohu.com Limited Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SOLS	Solstice Advanced Materials Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SONM	DNA X, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SONO	Sonos Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOPA	Society Pass Incorporated	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOPH	SOPHiA GENETICS SA Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SORA	AsiaStrategy	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SORN	Soren Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOTK	Sono-Tek Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOUN	SoundHound AI, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SOWG	Sow Good Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPAI	Safe Pro Group Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPCB	SuperCom Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPCM	Sound Point Acquisition Corp I, Ltd	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPCX	Space Exploration Technologies Corp. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPEG	Silver Pegasus Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPEGR	Silver Pegasus Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPFI	South Plains Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPGC	Newton Golf Company Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPHL	Springview Holdings Ltd Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPI	SPI Energy Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPKL	Spark I Acquisition Corp. Class A Ordinary Share	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPOK	Spok Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPPL	Simpple Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPRB	Spruce Biosciences, Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPRC	SciSparc Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPRO	Spero Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPRY	Ars Pharmaceuticals Inc	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPSC	SPS Commerce, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPT	Sprout Social Inc Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPTX	Seaport Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPWH	Sportsman's Warehouse Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SPWR	SunPower Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SQFT	Presidio Property Trust, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SQFTP	Presidio Property Trust 9.375% Perpetual Preferred Stock Series D	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SQL	SeqLL Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRAD	Sportradar Group AG Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRAX	SRAX Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRBK	SR Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRCE	1st Source Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRM	Tron Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRNE	Sorrento Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRPT	Sarepta Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRRK	Scholar Rock Holding Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRTA	Blade Air Mobility, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRTS	Sensus Healthcare Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SRZN	Surrozen, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSAC	SPACSphere Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSACR	SPACSphere Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSBI	Summit State Bank Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSEA	Starry Sea Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSEAR	Starry Sea Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSIC	Chicago Atlantic BDC Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSII	SS Innovations International, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSM	Sono Group N.V.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSNC	SS&C Technologies Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSNT	SilverSun Technologies Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSP	The E.W. Scripps Company Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSRM	SSR Mining Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSSSL	SuRo Capital Corp. Preferred Stock 6%	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SSTI	SoundThinking Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SSYS	Stratasys Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STAA	STAAR Surgical Company	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STAB	Statera Biopharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STAK	Stak Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STBA	S&T Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STEP	StepStone Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STEX	BioSig Technologies, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STFS	Star Fashion Culture Holdings Ltd. - Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STGW	Stagwell Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STHO	Star Holdings	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STI	Solidion Technology Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STIM	Neuronetics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STKE	Sol Strategies Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STKH	Steakholder Foods Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
STKS	The ONE Group Hospitality, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STLD	Steel Dynamics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STLN	Starling Oncology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STNE	StoneCo Ltd. Class A Common Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STOK	Stoke Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRA	Strategic Education Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRC	Strategy Inc	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
STRD	MicroStrategy Incorporated 10.00% Series A Perpetual Strife Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
STRF	Strategy Inc. 10.00% Series A Perpetual Strife Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
STRK	MicroStrategy Incorporated 8.00% Series A Perpetual Strike Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
STRL	Sterling Infrastructure, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRO	Sutro Biopharma Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRR	Star Equity Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRRP	Star Equity Holdings Inc. Preferred Stock Series A	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
STRT	Strattec Security Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STRZ	Starz Entertainment Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STTK	Shattuck Labs, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
STX	Seagate Technology Holdings plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUGP	SU Group Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUIG	Mill City Ventures III, Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUJA	Suja Life Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUMA	Suma Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUMAR	SUMA Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUNE	SUNation Energy Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUNS	Sunrise Realty Trust, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SUPN	Supernus Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SUPX	SuperX AI Technology Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SURG	SurgePays Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVAC	Spring Valley Acquisition Corp. III	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVAQ	Silicon Valley Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVC	Service Properties Trust	USD	NASDAQ	XNGS	United States	REIT	2026-09-14 21:16:47.001842+00	\N
SVCC	Stellar V Capital Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVCO	Silvaco Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVFD	Save Foods, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVIV	Spring Valley Acquisition Corp. IV Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVRA	Savara Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVRE	SaverOne 2014 Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SVRN	OceanPal Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SVVC	Firsthand Technology Value Fund, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWAG	Stran & Company, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWBI	Smith & Wesson Brands, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWIM	Latham Group, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWKHL	SWK Holdings Corp. 9% Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
SWKS	Skyworks Solutions, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWMR	Swarmer, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWRD	Stewards Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SWVL	Swvl Holdings Corp Class A Common Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SXTC	China SXT Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SXTP	60 Degrees Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SY	So-Young International Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
SYBT	Stock Yards Bancorp Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYM	Symbotic Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYNA	Synaptics Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYPR	Sypris Solutions Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYRA	Syra Health Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYRE	Spyre Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYRS	Syros Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SYTA	Core AI Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SZZL	Sizzle Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
SZZLR	Sizzle Acquisition Corp. II Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TACH	Titan Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TACO	Berto Acquisition Corp. Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TACT	TransAct Technologies Incorporated	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TANH	Tantech Holdings Ltd. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TAOP	Taoping Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TAOX	TAO Synergies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TARA	Protara Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TARS	Tarsus Pharmaceuticals Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TASK	TaskUs, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TATT	TAT Technologies Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TAVI	Tavia Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TAVIR	Tavia Acquisition Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TAYD	Taylor Devices, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TBBK	The Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TBCH	Turtle Beach Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TBLA	Taboola.com Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TBPH	Theravance Biopharma Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TBRG	TruBridge, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TC	Token Cat Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TCBI	Texas Capital Bancshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCBIO	Texas Capital Bancshares, Inc. 5.75% Fixed Rate Non-Cumulative Perpetual Preferred Stock, Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TCBK	TriCo Bancshares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCBS	Texas Community Bancshares, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCBX	Third Coast Bancshares, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCGX	TCGX Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCJH	Top KingWin Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCMD	Tactile Systems Technology, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCOM	Trip.com Group Limited American Depositary Receipt	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TCPC	BlackRock TCP Capital Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCRT	Alaunos Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCRX	TScan Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TCX	Tucows Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDAC	Translational Development Acquisition Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDIC	Dreamland Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDTH	Trident Digital Tech Holdings Ltd. Class B Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDUP	ThredUp Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDWD	Tailwind 2.0 Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TDWDR	Tailwind 2.0 Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TEAD	Teads Holding Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TEAM	Atlassian Corporation Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TECH	Bio-Techne Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TECX	Tectonic Therapeutic, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TELA	TELA Bio, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TELO	Telomir Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TEM	Tempus AI Inc Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TENB	Tenable Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TENX	Tenax Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TER	Teradyne, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TFIN	Triumph Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TFSL	TFS Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TGHL	The GrowHub Limited Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TGL	Treasure Global Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TGTX	TG Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TH	Target Hospitality Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THAR	Canton Strategic Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THCH	TH International Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THCP	Thunder Bridge Capital Partners IV Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THEO	BOA Acquisition Corp. II - Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THEOR	BOA Acquisition Corp. II Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THFF	First Financial Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THH	TryHard Holdings Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THRM	Gentherm Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
THRY	Thryv Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TIGO	Millicom International Cellular S.A.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TIGR	UP Fintech Holding Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TIL	Instil Bio Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TILE	Interface, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TIPT	Tiptree Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TITN	Titan Machinery Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TIVC	Valion Bio, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TJGC	TJGC Group Ltd. Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TKLF	Tokyo Lifestyle Co., Ltd. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TKNO	Alpha Teknova, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLF	Tandy Leather Factory, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLIH	Ten-League International Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLN	Talen Energy Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLNC	Talon Capital Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLPH	Talphera, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLRY	Tilray Brands Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLS	Telos Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLSA	Tiziana Life Sciences Ltd	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLSI	TriSalus Life Sciences, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TLX	Telix Pharmaceuticals Limited American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TMC	TMC The Metals Company Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMCI	Treace Medical Concepts Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMCR	The Metals Royalty Company Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMDX	TransMedics Group, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMS	Teamshares Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMTC	TMT Acquisition Corp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMTS	Spartacus Acquisition Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMUS	T-Mobile US Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TMUSI	T-Mobile US, Inc.	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TMUSL	T-Mobile USA, Inc.	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TMUSZ	T-Mobile USA, Inc.	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TNDM	Tandem Diabetes Care, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TNGX	Tango Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TNMG	TNL Mediagene Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TNON	Tenon Medical, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TNXP	Tonix Pharmaceuticals Holding Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TNYA	Tenaya Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOI	The Oncology Institute Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOMZ	TOMI Environmental Solutions, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TONX	Verb Technology Company, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOP	TOP Financial Group Ltd. Class A	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOPW	AsiaStrategy	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TORO	Toro Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOUR	Tuniu Corporation Sponsored ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TOWN	TowneBank	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TOYO	TOYO Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TPCS	TechPrecision Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TPG	TPG Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TPGXL	TPG Operating Group II 6.95 Preferred Stock	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TPST	Tempest Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRAW	Traws Pharma, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRAX	First Tracks Biotherapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRBG	Turbogen Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRDA	Entrada Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TREE	LendingTree Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TREO	Tactical Resources Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRGS	TRG Latin America Acquisitions Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRGSR	TRG Latin America Acquisitions Corp. Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRI	Thomson Reuters Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRIB	Trinity Biotech plc Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TRIN	Trinity Capital Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRINI	Trinity Capital Inc. 7.875% Notes Due 2029	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TRINZ	Trinity Capital Inc. 7.875% Notes due 2029	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
TRIP	Tripadvisor, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRMB	Trimble Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRMD	TORM plc Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRMK	Trustmark Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRNR	Interactive Strength Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRNS	Transcat Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRON	Tron Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TROO	TROOPS Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TROW	T. Rowe Price Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRS	TriMas Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRSG	Tungray Technologies Inc	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRST	TrustCo Bank Corp. NY	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRUG	TruGolf Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRUP	Trupanion Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TRVG	Trivago N.V. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TRVI	Trevi Therapeutics, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSAT	Telesat Corporation Class A Common Shares and Class B Variable Voting Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSBK	Timberland Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSCO	Tractor Supply Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSEM	Tower Semiconductor Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSHA	Taysha Gene Therapies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSIB	Tishman Speyer Innovation Corp. II	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSLA	Tesla, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TSSI	TSS, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTAN	ServiceTitan Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTD	The Trade Desk, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTEC	TTEC Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTEK	Tetra Tech Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTGT	TechTarget, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTMI	TTM Technologies, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTOO	T2 Biosystems, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTRX	Turn Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TTWO	Take-Two Interactive Software, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TUGC	TradeUP Global Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TULP	Bloomia Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TURB	Turbo Energy, S.A. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
TUSK	Mammoth Energy Services Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVA	Texas Ventures Acquisition III Corp Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVAI	Thayer Ventures Acquisition Corporation II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVAIR	Thayer Ventures Acquisition Corporation II Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVGN	Tevogen Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVIV	Texas Ventures Acquisition IV Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVRD	Tvardi Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TVTX	Travere Therapeutics Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TW	Tradeweb Markets Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWAV	TaoWeave Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWFG	TWFG, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWG	Top Wealth Group Holding Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWIN	Twin Disc, Incorporated	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWLVR	Twelve Seas Investment Company II Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TWST	Twist Bioscience Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TXG	10x Genomics Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TXMD	TherapeuticsMD, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TXN	Texas Instruments Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TXRH	Texas Roadhouse Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TYGO	Tigo Energy, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TYRA	Tyra Biosciences, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
TZOO	Travelzoo Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UAL	United Airlines Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UBCP	United Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UBOH	United Bancshares Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UBSI	United Bankshares Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UBX	Unity Biotechnology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UCAR	U Power Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UCBI	United Community Banks, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UCFI	CN Healthy Food Tech Group Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UCL	uCloudlink Group Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
UCTT	Ultra Clean Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UEIC	Universal Electronics Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UFCS	United Fire Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UFG	Uni-Fuels Holdings Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UFPI	UFP Industries, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UFPT	UFP Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UG	United-Guardian, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UGLD	VelocityShares 3x Long Gold ETN linked to the S&P GSCI Gold Index	USD	NASDAQ	XNMS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
UGRO	urban-gro, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UK	Ucommune International Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ULBI	Ultralife Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ULCC	Frontier Group Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ULH	Universal Logistics Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ULTA	Ulta Beauty, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UMBF	UMB Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UMBFO	UMB Financial Corporation 7.75% Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
UNB	Union Bankshares, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UNCY	Unicycive Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UNIT	Uniti Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UNTY	Unity Bancorp Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UONE	Urban One Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UONEK	Urban One, Inc. Class D Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPB	Upstream Bio, Inc. Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPBD	Upbound Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPC	Universe Pharmaceuticals Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPLD	Upland Software Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPST	Upstart Holdings Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPWK	Upwork Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UPXI	Upexi Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
URBN	Urban Outfitters Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
URGN	UroGen Pharma Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UROY	Uranium Royalty Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USAR	USA Rare Earth, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USAU	U.S. Gold Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USCB	USCB Financial Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USDE	StablecoinX Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USDEW	StablecoinX Inc. Warrants	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USEA	United Maritime Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USGO	U.S. GoldMining Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USIO	Usio Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USLM	United States Lime & Minerals, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
USLV	VelocityShares 3x Long Silver ETN linked to the S&P GSCI Silver Index	USD	NASDAQ	XNMS	United States	Exchange-Traded Note	2026-09-14 21:16:47.001842+00	\N
UTHR	United Therapeutics Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UTMD	Utah Medical Products, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UTRS	Minerva Surgical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UTSI	UTStarcom Holdings Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UVSP	Univest Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UXIN	Uxin Ltd. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
UYSC	UY Scuti Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UYSCR	UY Scuti Acquisition Corp. Rights	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
UZX	Linkage Global Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VABK	Virginia National Bankshares Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VAI	Valor Energy Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VALN	Valneva SE Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VALU	Value Line Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VANI	Vivani Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VBNK	VersaBank	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VC	Visteon Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VCEL	Vericel Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VCIG	VCI Global Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VCRE	Vicore Pharma Holding AB	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VCTR	Victory Capital Holdings, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VCYT	Veracyte, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VECO	Veeco Instruments Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VEEA	Veea Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VEEE	Twin Vee PowerCats Co. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VELO	Velo3D Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VENA	Venus Acquisition Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VEON	VEON Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VERA	Vera Therapeutics, Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VERB	TON Strategy Company	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VERI	Veritone Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VERU	Veru Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VERX	Vertex Inc. Class A	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VEV	Vicinity Motor Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VFF	Village Farms International Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VFS	VinFast Auto Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VGAS	Verde Clean Fuels, Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VHCP	Vine Hill Capital Investment Corp. II	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIA	Via Transportation Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIAV	Viavi Solutions Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VICR	Vicor Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VII	7GC & Co. Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VINC	Vincerx Pharma Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VINO	Gaucho Group Holdings, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VINP	Vinci Compass Investments Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIOT	Viomi Technology Co Ltd ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VIP	Vulcan Infrastructure and Power Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIR	Vir Biotechnology, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIRC	Virco Manufacturing Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIRI	Dogwood Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VISL	Vislink Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VISN	Vistance Networks, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VITL	Vital Farms, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIVE	Viveve Medical Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIVO	Meridian Bioscience Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VIVS	VivoSim Labs Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VKTX	Viking Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLCN	Empery Digital Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLGEA	Village Super Market Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLON	Vallon Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLOS	Velos Acquisition I Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLY	Valley National Bancorp Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VLYPN	Valley National Bancorp 8.250% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series C	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
VLYPO	Valley National Bancorp 5.50% Fixed-to-Floating Rate Non-Cumulative Perpetual Preferred Stock, Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
VLYPP	Valley National Bancorp 6.25% Fixed-to-Floating Rate Series A Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
VMAR	Vision Marine Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VMD	Viemed Healthcare, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VMET	Versamet Royalties Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VNDA	Vanda Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VNET	VNET Group, Inc. ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VNME	Vendome Acquisition Corp I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VNOM	Viper Energy, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VOD	Vodafone Group plc Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VOGX	Vogenx Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VOR	Vor Biopharma Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VOXR	Vox Royalty Corp. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRA	Vera Bradley Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRAR	Brightline Interactive Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRAX	Virax Biolabs Group Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRCA	Verrica Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRDN	Viridian Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VREX	Varex Imaging Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRM	Vroom Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRME	VerifyMe Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRNS	Varonis Systems, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRPX	Virpax Pharmaceuticals Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRRM	Verra Mobility Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRSK	Verisk Analytics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRSN	VeriSign, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRSSF	Verses AI Inc.	USD	NASDAQ	XNAS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRTX	Vertex Pharmaceuticals Incorporated Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VRXA	Veraxa Biotech AG	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VS	Versus Systems Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSA	VisionSys AI Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
VSAT	Viasat Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSEC	VSE Corporation Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSECU	VSE CORP TANGIBLE EQUITY UNIT (01/02/2029)	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSME	VS Media Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSNT	Versant Media Group Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VSTM	Verastem Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VTGN	Vistagen Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VTIX	Virtuix Holdings Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VTRS	Viatris Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VTSI	VirTra, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VTVT	vTv Therapeutics Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VUZI	Vuzix Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VVOS	Vivos Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VVPR	VivoPower PLC	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VWAV	VisionWave Holdings Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VWE	Vintage Wine Estates, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VYGR	Voyager Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
VYNE	Vyne Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WABC	Westamerica Bancorporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WAFD	WaFd, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WAFDP	WaFd, Inc. 4.875% Fixed Rate Series A Non-Cumulative Perpetual Preferred Stock	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WAFU	Wah Fu Education Group Limited Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WALD	Waldencast plc Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WASH	Washington Trust Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WATR	Air Water Ventures Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WATT	Energous Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WAVD	WaveDancer, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WAVE	Eco Wave Power Global AB Sponsored ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
WAY	Waystar Holding Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WB	Weibo Corporation Sponsored ADR	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
WBD	Warner Bros. Discovery, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WBTN	Webtoon Entertainment Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WBUY	Webuy Global Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WCT	Wellchange Holdings Company Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WDAY	Workday Inc Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WDC	Western Digital Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WDFC	WD-40 Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WEN	The Wendy's Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WENN	Wen Acquisition Corp Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WERN	Werner Enterprises Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WEST	Westrock Coffee Co.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WETF	WisdomTree Investments Inc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WETH	Wetouch Technology Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WETO	Wetour Robotics Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WEYS	Weyco Group Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WFCF	Where Food Comes From Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WFF	WF Holding Limited Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WFRD	Weatherford International plc	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WGS	GeneDx Holdings Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WHF	WhiteHorse Finance Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WHFCL	WhiteHorse Finance, Inc. - 7.875% Notes due 2028	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WHLR	Wheeler Real Estate Investment Trust, Inc.	USD	NASDAQ	XNCM	United States	REIT	2026-09-14 21:16:47.001842+00	\N
WHLRD	Wheeler Real Estate Investment Trust, Inc. 8.75% Preferred Stock	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WHLRP	Wheeler Real Estate Investment Trust, Inc. Preferred Stock 9% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WHWK	Whitehawk Therapeutics, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WILC	G. Willi-Food International Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WIMI	WiMi Hologram Cloud Inc. Class B Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WINA	Winmark Corporation	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WING	Wingstop Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WINV	Winvest Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WINVR	Winvest Acquisition Corp. Rights	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WISA	Wisa Technologies Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WISH	ContextLogic Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WIX	Wix.com Ltd.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WKEY	WISeKey International Holding Ltd. ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
WKHS	Workhorse Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WKSP	Worksport Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLCO	Wilco 63 Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLDN	Willdan Group Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLDS	Wearable Devices Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLFC	Willis Lease Finance Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLGS	Wang & Lee Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLII	Willow Lane Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WLTW	Willis Towers Watson Public Limited Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WMG	Warner Music Group Corp.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WMT	Walmart Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WNEB	Western New England Bancorp, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WNW	Meiwu Technology Co., Ltd. Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WOK	Work Medical Technology Group Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WOOF	Petco Health and Wellness Company, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WPRT	Westport Fuel Systems Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WRAP	Wrap Technologies, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WRD	WeRide Inc. American Depositary Receipt	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
WRLD	World Acceptance Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSBC	WesBanco, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSBCO	WesBanco, Inc. 7.375% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series B	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WSBF	Waterstone Financial Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSBK	Winchester Bancorp Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSC	WillScot Holdings Corporation	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSE	Wise Group plc Class A Ordinary Shares	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSFS	WSFS Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSHP	WeShop Holdings Limited Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WSTNR	Westin Acquisition Corp Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTBA	West Bancorporation Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTER	The Alkaline Water Company Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTF	Waton Financial Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTFC	Wintrust Financial Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTFCN	Wintrust Financial Corporation 7.875% Fixed-Rate Reset Non-Cumulative Perpetual Preferred Stock, Series F	USD	NASDAQ	XNGS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WTG	Wintergreen Acquisition Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTGUR	Wintergreen Acquisition Corp. Rights	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WTW	Willis Towers Watson Public Limited Company	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WULF	TeraWulf Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WVE	Wave Life Sciences Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WVFC	WVS Financial Corp	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WVVI	Willamette Valley Vineyards Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WVVIP	Willamette Valley Vineyards Preferred Stock 5.3% Perpetual	USD	NASDAQ	XNCM	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
WW	WW International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WWAC	Worldwide Webb Acquisition Corp. Class A Ordinary Share	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WWD	Woodward, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WXM	WF International Limited Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WYFI	WhiteFiber Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WYHG	Wing Yip Food Holdings Group Limited American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
WYNN	Wynn Resorts, Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
WYTC	Wytec International Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XAIR	Beyond Air Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XBIO	Xenetic Biosciences, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XBIT	XBiotech Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XBP	XBP Global Holdings Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XCBE	X3 Acquisition Corp. Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XCH	XCHG Limited American Depositary Share	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
XCUR	Exicure Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XE	X-Energy, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XEL	Xcel Energy Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XELB	Xcel Brands, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XELLL	Xcel Energy Inc. 6.25% Junior Subordinated Notes due 2085	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
XENE	Xenon Pharmaceuticals Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XERS	Xeris Biopharma Holdings, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XFOR	X4 Pharmaceuticals, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XGN	Exagen Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XHG	XChange TEC Inc. American Depositary Shares	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
XHLD	Ten Holdings, Inc. Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XLAB	Exascale Labs Holdings Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XLO	Xilio Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XMAX	XMax Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XMTR	Xometry Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XNCR	Xencor Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XNDU	Xanadu Quantum Technologies Limited Class B Subordinate Voting Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XNET	Xunlei Limited American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
XOS	Xos, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XP	XP Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XPDB	Power & Digital Infrastructure Acquisition II Corp.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XPEL	XPEL Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XPON	Expion360 Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XRAY	Dentsply Sirona Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XRPN	Armada Acquisition Corp. II Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XRTX	XORTX Therapeutics Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XRX	Xerox Holdings Corporation	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XSLL	Xsolla SPAC 1 Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XTER	Karman Line Acquisition Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XTIA	XTI Aerospace, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XTLB	XTL Biopharmaceuticals Ltd. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
XWEL	XWELL Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
XXII	22nd Century Group Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YAAS	Youxin Technology Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YARW	Yarrow Bioscience, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YB	Yuanbao Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YDDL	One and One Green Technologies, Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YDES	YD Bio Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YDKG	AirNet Technology Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YFOR	YYForce Inc. Class A Common Stock	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YGMZ	MingZhu Logistics Holdings Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YHC	LQR House Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YHGJ	Yunhong Green CTI Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YHNA	YHN Acquisition I Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YHNAR	YHN Acquisition I Limited Right	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YI	111, Inc. American Depositary Receipt	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YIBO	Planet Image International Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YICC	Yorkville International Capital Corp. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YJ	Yunji Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YMAT	J-Star Holding Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YMT	Yimutian Inc. American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YORW	York Water Co.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YOSH	Yoshiharu Global Co.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YOTA	Yotta Acquisition Corp	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YOUL	Youlife Group Inc. ADR	USD	NASDAQ	XNCM	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YQ	17 Education & Technology Group Inc. American Depositary Shares	USD	NASDAQ	XNGS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YRIV	Yangtze River Port and Logistics Limited	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YSWY	Yesway Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YSXT	YSX Tech Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YTRA	Yatra Online, Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YXT	YXT.COM Group Holding Limited American Depositary Shares	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YY	JOYY Inc. American Depositary Shares	USD	NASDAQ	XNGS	United States	Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
YYAI	AiRWA Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
YYGH	YYForce Inc. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
Z	Zillow Group Inc. Class C Capital Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZAZZT	ZAZZT	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZBAO	Zhibao Technology Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZBIO	Zenas BioPharma, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZBRA	Zebra Technologies Corp. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZBZZT	ZBZZT	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZCMD	Zhongchao Inc. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZD	Ziff Davis, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZDAI	DirectBooking Technology Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZENA	ZenaTech Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZENV	Zenvia Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZEO	Zeo Energy Corp. Class A Common Stock	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZG	Zillow Group, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZION	Zions Bancorporation, National Association	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZIONP	Zions Bancorporation N.A. Preferred Stock 5.37372% Perpetual	USD	NASDAQ	XNMS	United States	Preferred Stock	2026-09-14 21:16:47.001842+00	\N
ZIVO	Zivo Bioscience Inc.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZJK	ZJK Industrial Co., Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZJYL	Jin Medical International Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZKIN	ZK International Group Co., Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZKP	Lafayette Digital Acquisition Corp. I Class A Ordinary Shares	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZLAB	Zai Lab Limited ADR	USD	NASDAQ	XNMS	United States	American Depositary Receipt	2026-09-14 21:16:47.001842+00	\N
ZM	Zoom Communications, Inc. Class A Common Stock	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZNB	Color Star Technology Co., Ltd.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZNTL	Zentalis Pharmaceuticals, Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZOOZ	Zooz Strategy Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZS	Zscaler Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZSQR	Z Squared Inc.	USD	NASDAQ	XNMS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZSTK	ZeroStack Corp.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZTEK	Zentek Ltd.	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZTG	Zenta Group Co. Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZUMZ	Zumiez Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZURA	Zura Bio Limited	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZVRA	Zevra Therapeutics, Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZVZZT		USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZYBT	Zhengye Biotechnology Holding Ltd. Class A Ordinary Shares	USD	NASDAQ	XNCM	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
ZYME	Zymeworks Inc.	USD	NASDAQ	XNGS	United States	Common Stock	2026-09-14 21:16:47.001842+00	\N
\.


--
-- Data for Name: user_stocks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_stocks (user_id, symbol, added_at) FROM stdin;
1	TSLA	2026-09-14 21:16:19.817873+00
1	AAPL	2026-09-14 21:16:19.817873+00
1	NFLX	2026-09-14 21:16:19.817873+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, username, full_name, password_hash, created_at) FROM stdin;
1	juan@demo.com	Juan Perez	$argon2id$v=19$m=65536,t=3,p=4$+nN/4RUBgC/pfp8GdihYeQ$IO10V588iHwNUnRAvUIouGfT+Q+KqYx9ORqinCoXrKw	2026-09-14 21:16:19.817873+00
2	ana@demo.com	Ana Gomez	$argon2id$v=19$m=65536,t=3,p=4$+ZdzMKg8wD9f6OkqUsGrAw$qEa+qcmmbOJISwSLCum7ZaBZZ6pTGcRV2G2MoIu7/eY	2026-09-14 21:16:19.817873+00
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (symbol, "interval", ts);


--
-- Name: stocks stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks
    ADD CONSTRAINT stocks_pkey PRIMARY KEY (symbol);


--
-- Name: user_stocks user_stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stocks
    ADD CONSTRAINT user_stocks_pkey PRIMARY KEY (user_id, symbol);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: ix_quotes_symbol_interval_ts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_quotes_symbol_interval_ts ON public.quotes USING btree (symbol, "interval", ts DESC);


--
-- Name: ix_stocks_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_stocks_name_trgm ON public.stocks USING gin (name public.gin_trgm_ops);


--
-- Name: ix_stocks_symbol_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_stocks_symbol_trgm ON public.stocks USING gin (symbol public.gin_trgm_ops);


--
-- Name: quotes quotes_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.stocks(symbol);


--
-- Name: user_stocks user_stocks_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stocks
    ADD CONSTRAINT user_stocks_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.stocks(symbol);


--
-- Name: user_stocks user_stocks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_stocks
    ADD CONSTRAINT user_stocks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 7KtPhTTh4uQBIIfLxiS92iFa05uHHQmLqw7nwgiTrO8E5e9DCm5baTteUe9Ued7
