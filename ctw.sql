--
-- PostgreSQL database dump
--

\restrict MXAAZ7YjfdGX2vGCu7yzUNK2cTpAVgWJbjZsIyOeXIHAipocnw91JlUvEzNNfxV

-- Dumped from database version 16.15
-- Dumped by pg_dump version 16.15

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

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: ctw_touch_updated_at(); Type: FUNCTION; Schema: public; Owner: ctw_admin
--

CREATE FUNCTION public.ctw_touch_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;


ALTER FUNCTION public.ctw_touch_updated_at() OWNER TO ctw_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ctw_admin_user; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_admin_user (
    admin_id integer NOT NULL,
    login_id text NOT NULL,
    full_name text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login_at timestamp with time zone,
    mfa_secret_enc text,
    mfa_enabled boolean DEFAULT false NOT NULL,
    mfa_last_step bigint,
    recovery_codes text[] DEFAULT '{}'::text[] NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    password_changed_at timestamp with time zone,
    session_version integer DEFAULT 1 NOT NULL,
    created_by integer
);


ALTER TABLE public.ctw_admin_user OWNER TO ctw_admin;

--
-- Name: TABLE ctw_admin_user; Type: COMMENT; Schema: public; Owner: ctw_admin
--

COMMENT ON TABLE public.ctw_admin_user IS 'CTW staff who may onboard clients and generate their images';


--
-- Name: COLUMN ctw_admin_user.mfa_secret_enc; Type: COMMENT; Schema: public; Owner: ctw_admin
--

COMMENT ON COLUMN public.ctw_admin_user.mfa_secret_enc IS 'TOTP secret, encrypted with CTW_DATA_KEY; never returned by the API';


--
-- Name: ctw_admin_user_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: ctw_admin
--

CREATE SEQUENCE public.ctw_admin_user_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ctw_admin_user_admin_id_seq OWNER TO ctw_admin;

--
-- Name: ctw_admin_user_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctw_admin
--

ALTER SEQUENCE public.ctw_admin_user_admin_id_seq OWNED BY public.ctw_admin_user.admin_id;


--
-- Name: ctw_audit_log; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_audit_log (
    audit_id bigint NOT NULL,
    at timestamp with time zone DEFAULT now() NOT NULL,
    admin_id integer,
    action text NOT NULL,
    customer_id text,
    details jsonb DEFAULT '{}'::jsonb NOT NULL
);


ALTER TABLE public.ctw_audit_log OWNER TO ctw_admin;

--
-- Name: ctw_audit_log_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: ctw_admin
--

CREATE SEQUENCE public.ctw_audit_log_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ctw_audit_log_audit_id_seq OWNER TO ctw_admin;

--
-- Name: ctw_audit_log_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctw_admin
--

ALTER SEQUENCE public.ctw_audit_log_audit_id_seq OWNED BY public.ctw_audit_log.audit_id;


--
-- Name: ctw_build; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_build (
    build_id bigint NOT NULL,
    customer_id text NOT NULL,
    version integer NOT NULL,
    build_type text NOT NULL,
    based_on_build bigint,
    status text DEFAULT 'queued'::text NOT NULL,
    instance_id uuid,
    licence_seal text,
    image_tag text,
    image_size_bytes bigint,
    artifact_dir text,
    spec_snapshot jsonb,
    log text DEFAULT ''::text NOT NULL,
    error text,
    requested_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    files_removed_at timestamp with time zone,
    CONSTRAINT ctw_build_build_type_check CHECK ((build_type = ANY (ARRAY['full'::text, 'image_only'::text]))),
    CONSTRAINT ctw_build_check CHECK (((build_type = 'full'::text) OR (based_on_build IS NOT NULL))),
    CONSTRAINT ctw_build_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'success'::text, 'failed'::text])))
);


ALTER TABLE public.ctw_build OWNER TO ctw_admin;

--
-- Name: ctw_build_build_id_seq; Type: SEQUENCE; Schema: public; Owner: ctw_admin
--

CREATE SEQUENCE public.ctw_build_build_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ctw_build_build_id_seq OWNER TO ctw_admin;

--
-- Name: ctw_build_build_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ctw_admin
--

ALTER SEQUENCE public.ctw_build_build_id_seq OWNED BY public.ctw_build.build_id;


--
-- Name: ctw_client; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client (
    customer_id text NOT NULL,
    customer_name text NOT NULL,
    category text,
    industry text,
    primary_domain text,
    deployment_fqdn text,
    status text DEFAULT 'draft'::text NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ctw_client_category_check CHECK ((category = ANY (ARRAY['Enterprise'::text, 'Mid-Market'::text, 'SMB'::text, 'Government'::text, 'Financial Institution'::text]))),
    CONSTRAINT ctw_client_customer_id_check CHECK ((customer_id ~ '^[A-Za-z0-9_-]{3,32}$'::text)),
    CONSTRAINT ctw_client_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'ready'::text, 'generated'::text, 'live'::text, 'suspended'::text])))
);


ALTER TABLE public.ctw_client OWNER TO ctw_admin;

--
-- Name: ctw_client_contact; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_contact (
    contact_id text NOT NULL,
    customer_id text NOT NULL,
    office_id text,
    contact_type text,
    contact_priority integer,
    contact_person text,
    designation text,
    department text,
    contact_email text,
    contact_phone text,
    CONSTRAINT ctw_client_contact_contact_priority_check CHECK ((contact_priority > 0)),
    CONSTRAINT ctw_client_contact_contact_type_check CHECK ((contact_type = ANY (ARRAY['Executive'::text, 'Primary vCISO'::text, 'IT Security'::text, 'Escalation'::text, 'Emergency'::text])))
);


ALTER TABLE public.ctw_client_contact OWNER TO ctw_admin;

--
-- Name: ctw_client_initial_user; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_initial_user (
    customer_id text NOT NULL,
    user_id text NOT NULL,
    login_id text,
    user_name text,
    user_email text,
    user_mobile text,
    designation text,
    department text,
    role_type text,
    office_id text,
    CONSTRAINT ctw_client_initial_user_role_type_check CHECK ((role_type = ANY (ARRAY['vCISO'::text, 'Organisation Owner'::text, 'Control Owner'::text, 'Auditor'::text, 'Viewer'::text])))
);


ALTER TABLE public.ctw_client_initial_user OWNER TO ctw_admin;

--
-- Name: ctw_client_news_watch; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_news_watch (
    customer_id text NOT NULL,
    monitored_names text[] DEFAULT '{}'::text[] NOT NULL,
    monitored_domains text[] DEFAULT '{}'::text[] NOT NULL,
    monitored_cities text[] DEFAULT '{}'::text[] NOT NULL,
    custom_keywords text[] DEFAULT '{}'::text[] NOT NULL
);


ALTER TABLE public.ctw_client_news_watch OWNER TO ctw_admin;

--
-- Name: ctw_client_office; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_office (
    office_id text NOT NULL,
    customer_id text NOT NULL,
    office_type text,
    office_address text,
    city text,
    state text,
    country text,
    pincode text,
    CONSTRAINT ctw_client_office_office_type_check CHECK ((office_type = ANY (ARRAY['Primary'::text, 'Secondary'::text, 'Data Center'::text, 'Regional Office'::text])))
);


ALTER TABLE public.ctw_client_office OWNER TO ctw_admin;

--
-- Name: ctw_client_security_policy; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_security_policy (
    customer_id text NOT NULL,
    sso_type text DEFAULT 'LOCAL'::text,
    sso_metadata_url text,
    mfa_enforced boolean DEFAULT true,
    password_expiry_days integer,
    session_timeout_minutes integer,
    CONSTRAINT ctw_client_security_policy_password_expiry_days_check CHECK ((password_expiry_days > 0)),
    CONSTRAINT ctw_client_security_policy_session_timeout_minutes_check CHECK ((session_timeout_minutes > 0)),
    CONSTRAINT ctw_client_security_policy_sso_type_check CHECK ((sso_type = ANY (ARRAY['LOCAL'::text, 'SAML_2_0'::text, 'OIDC'::text, 'AZURE_AD'::text, 'OKTA'::text])))
);


ALTER TABLE public.ctw_client_security_policy OWNER TO ctw_admin;

--
-- Name: ctw_client_tool; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_client_tool (
    customer_id text NOT NULL,
    tool_name text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    target_endpoint text,
    pull_frequency_per_day integer,
    sort_order integer DEFAULT 0 NOT NULL,
    CONSTRAINT ctw_client_tool_pull_frequency_per_day_check CHECK ((pull_frequency_per_day >= 0)),
    CONSTRAINT ctw_client_tool_tool_name_check CHECK ((tool_name = ANY (ARRAY['Tenable'::text, 'Qualys'::text, 'Rapid7'::text, 'Greenbone'::text, 'McAfee'::text, 'Zscaler'::text])))
);


ALTER TABLE public.ctw_client_tool OWNER TO ctw_admin;

--
-- Name: ctw_contract; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_contract (
    customer_id text NOT NULL,
    contract_id text NOT NULL,
    customer_ref_po text,
    contract_type text,
    financial_year integer,
    contract_period_months integer,
    contract_start_date date,
    contract_end_date date,
    contract_value numeric(14,2),
    currency text,
    invoicing_frequency text,
    is_current boolean DEFAULT true NOT NULL,
    CONSTRAINT ctw_contract_check CHECK ((contract_end_date > contract_start_date)),
    CONSTRAINT ctw_contract_contract_period_months_check CHECK ((contract_period_months > 0)),
    CONSTRAINT ctw_contract_contract_type_check CHECK ((contract_type = ANY (ARRAY['Original'::text, 'Extension'::text, 'AMC'::text, 'AR'::text, 'CR'::text]))),
    CONSTRAINT ctw_contract_invoicing_frequency_check CHECK ((invoicing_frequency = ANY (ARRAY['M'::text, 'Q'::text, 'H'::text, 'Y'::text])))
);


ALTER TABLE public.ctw_contract OWNER TO ctw_admin;

--
-- Name: ctw_framework; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_framework (
    framework_id integer NOT NULL,
    framework_name text NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.ctw_framework OWNER TO ctw_admin;

--
-- Name: ctw_licence; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_licence (
    customer_id text NOT NULL,
    max_users integer,
    max_vcisos integer,
    max_org_owners integer,
    max_control_owners integer,
    max_api_integrations integer,
    max_frameworks integer,
    valid_to date,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ctw_licence_max_api_integrations_check CHECK ((max_api_integrations >= 0)),
    CONSTRAINT ctw_licence_max_control_owners_check CHECK ((max_control_owners >= 0)),
    CONSTRAINT ctw_licence_max_frameworks_check CHECK ((max_frameworks > 0)),
    CONSTRAINT ctw_licence_max_org_owners_check CHECK ((max_org_owners >= 0)),
    CONSTRAINT ctw_licence_max_users_check CHECK ((max_users > 0)),
    CONSTRAINT ctw_licence_max_vcisos_check CHECK ((max_vcisos >= 0))
);


ALTER TABLE public.ctw_licence OWNER TO ctw_admin;

--
-- Name: ctw_licence_framework; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_licence_framework (
    customer_id text NOT NULL,
    framework_id integer NOT NULL,
    review_frequency_months integer,
    CONSTRAINT ctw_licence_framework_review_frequency_months_check CHECK ((review_frequency_months > 0))
);


ALTER TABLE public.ctw_licence_framework OWNER TO ctw_admin;

--
-- Name: ctw_licence_framework_office; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_licence_framework_office (
    customer_id text NOT NULL,
    framework_id integer NOT NULL,
    office_id text NOT NULL
);


ALTER TABLE public.ctw_licence_framework_office OWNER TO ctw_admin;

--
-- Name: ctw_licence_module; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_licence_module (
    customer_id text NOT NULL,
    module_name text NOT NULL
);


ALTER TABLE public.ctw_licence_module OWNER TO ctw_admin;

--
-- Name: ctw_migration; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_migration (
    name text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ctw_migration OWNER TO ctw_admin;

--
-- Name: ctw_module; Type: TABLE; Schema: public; Owner: ctw_admin
--

CREATE TABLE public.ctw_module (
    module_name text NOT NULL,
    mandatory boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.ctw_module OWNER TO ctw_admin;

--
-- Name: ctw_admin_user admin_id; Type: DEFAULT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_admin_user ALTER COLUMN admin_id SET DEFAULT nextval('public.ctw_admin_user_admin_id_seq'::regclass);


--
-- Name: ctw_audit_log audit_id; Type: DEFAULT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_audit_log ALTER COLUMN audit_id SET DEFAULT nextval('public.ctw_audit_log_audit_id_seq'::regclass);


--
-- Name: ctw_build build_id; Type: DEFAULT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build ALTER COLUMN build_id SET DEFAULT nextval('public.ctw_build_build_id_seq'::regclass);


--
-- Data for Name: ctw_admin_user; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_admin_user VALUES (5, 'ui.tester', 'UI Tester', 'ui.tester@cybertrustworks.example', '$2a$10$lTNwhYueUhcEZ67G5JiyGegUXmKMA/VCcgj614guhBfWCDHLvBG2q', false, '2026-10-21 06:07:23.512107+00', '2026-10-21 06:07:27.027568+00', 'v1:9zzsbJ_nRL_x0T8r:_rCRQnEpb7qnJk-NZfsQkA:TZHLOCUVd1286-ukE-G8mRHIh9MI7MtoHyMTicWwYvQ', true, 59752095, '{0fc903f7953e11e10cb6da5c8ded6e573111d685c7507c159de868e52e41f58d,688fd7cce1d2e692f20b0a1894d800177d0e4680f5827996ff4847964944893a,b847a134f8401d8525b8cd1cd0de58f96d5c41a80aa7072bc5fbdbb91311cc18,ada75fb4116edc03b34e574537259adb0fa373dba274fba50be995ff255d30ba,381f020dfbf189eb97d6adbf20c93db2cb2c7c0cad6f9b852fffdd1ba5170355,072e7de474f68b26ce0b27c49b64249125d6a2c77d251e2051735a79d764ecfc,c94f3e2cd48dd9cfe707802f5e79c5481ed8a615b621fb49e5f564432641a3ee,b186e5864b51133591deed1f7bfa87ed0f7666bce59fbbaaf32639d3386d58d4,ba2852b9ed07dfc7d834e3373df5567a49f67da01cc2c2e49282a5f6215b5d6e,1b2667a5586ef3edaf9a5e57e9c25b51f7803fb106403fbfcdc8b49968ffc5e9}', false, '2026-10-21 06:07:25.005394+00', 4, 1);
INSERT INTO public.ctw_admin_user VALUES (2, 'e2e.ops', 'E2E Test Operator', 'e2e.ops@cybertrustworks.example', '$2a$10$h1PH.oGx5gjIOIP/tivSN.YLDxECkd9I/aKSDmdWtBh0d7LRz0Umm', false, '2026-10-21 06:01:50.06547+00', '2026-10-21 06:01:50.287485+00', NULL, false, NULL, '{}', true, '2026-10-21 06:01:50.407872+00', 5, 1);
INSERT INTO public.ctw_admin_user VALUES (1, 'ctw.admin', 'CTW Administrator', 'admin@cybertrustworks.example', '$2a$10$gdqo4xMZT4XQq9GHl4gXTed6A6EMLZXgN.GRIvJhUm5NgTMpWbzzu', true, '2026-10-21 04:54:09.867394+00', '2026-10-21 06:55:36.937025+00', NULL, false, NULL, '{}', false, NULL, 8, NULL);
INSERT INTO public.ctw_admin_user VALUES (7, 'anish', 'Anish', 'anish@gmail.com', '$2a$10$LWEgQtAdxw90yf7lzwgDpeb.g0JvN..V3HmQca0HiBF3F7TxCDcRa', true, '2026-10-21 06:53:54.199716+00', '2026-10-21 18:15:55.125486+00', NULL, false, NULL, '{}', false, NULL, 1, NULL);


--
-- Data for Name: ctw_audit_log; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_audit_log VALUES (1, '2026-10-21 04:54:09.91842+00', 1, 'admin.create', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (2, '2026-10-21 04:54:09.922004+00', 1, 'client.import', 'Cust_00101', '{"source": "spec"}');
INSERT INTO public.ctw_audit_log VALUES (3, '2026-10-21 05:02:46.151896+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (4, '2026-10-21 05:02:47.610409+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (5, '2026-10-21 05:02:47.633239+00', 1, 'client.create', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (6, '2026-10-21 05:02:47.695539+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (7, '2026-10-21 05:02:48.50956+00', 1, 'client.validate', 'Cust_00202', '{"valid": false, "errors": 2}');
INSERT INTO public.ctw_audit_log VALUES (8, '2026-10-21 05:02:48.51426+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (9, '2026-10-21 05:02:49.355401+00', 1, 'client.validate', 'Cust_00202', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (10, '2026-10-21 05:02:49.410818+00', 1, 'client.delete', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (11, '2026-10-21 05:03:12.619172+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (12, '2026-10-21 05:03:14.686592+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (13, '2026-10-21 05:03:14.695304+00', 1, 'client.create', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (14, '2026-10-21 05:03:14.758866+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (15, '2026-10-21 05:03:16.063483+00', 1, 'client.validate', 'Cust_00202', '{"valid": false, "errors": 2}');
INSERT INTO public.ctw_audit_log VALUES (16, '2026-10-21 05:03:16.081854+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (17, '2026-10-21 05:03:16.461002+00', 1, 'client.validate', 'Cust_00202', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (18, '2026-10-21 05:03:16.507536+00', 1, 'client.delete', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (19, '2026-10-21 05:13:25.643109+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (20, '2026-10-21 05:13:26.278489+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (21, '2026-10-21 05:13:26.292022+00', 1, 'client.create', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (22, '2026-10-21 05:13:26.385849+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (23, '2026-10-21 05:13:26.824926+00', 1, 'client.validate', 'Cust_00202', '{"valid": false, "errors": 2}');
INSERT INTO public.ctw_audit_log VALUES (24, '2026-10-21 05:13:26.832328+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (25, '2026-10-21 05:13:27.301549+00', 1, 'client.validate', 'Cust_00202', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (26, '2026-10-21 05:13:27.347422+00', 1, 'client.delete', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (27, '2026-10-21 05:13:27.586593+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (28, '2026-10-21 05:13:28.051801+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (29, '2026-10-21 05:13:28.071451+00', 1, 'client.create', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (30, '2026-10-21 05:13:28.165468+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (31, '2026-10-21 05:13:28.728754+00', 1, 'client.validate', 'Cust_00202', '{"valid": false, "errors": 2}');
INSERT INTO public.ctw_audit_log VALUES (32, '2026-10-21 05:13:28.737685+00', 1, 'client.update', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (33, '2026-10-21 05:13:29.115185+00', 1, 'client.validate', 'Cust_00202', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (34, '2026-10-21 05:13:29.149643+00', 1, 'client.delete', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (35, '2026-10-21 05:25:10.646757+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (36, '2026-10-21 05:25:10.697358+00', 1, 'client.create', 'Cust_00909', '{}');
INSERT INTO public.ctw_audit_log VALUES (37, '2026-10-21 05:25:10.760068+00', 1, 'client.delete', 'Cust_00909', '{}');
INSERT INTO public.ctw_audit_log VALUES (38, '2026-10-21 05:25:10.79102+00', 1, 'build.start', 'Cust_00101', '{"version": 1, "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (39, '2026-10-21 05:25:19.82032+00', 1, 'build.success', 'Cust_00101', '{"users": 2, "version": 1, "build_id": "2", "image_tag": "cybertrustworks/vciso-platform:cust_00101-v1"}');
INSERT INTO public.ctw_audit_log VALUES (40, '2026-10-21 05:25:21.106516+00', 1, 'build.credentials', 'Cust_00101', '{"given": true, "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (41, '2026-10-21 05:25:21.123737+00', 1, 'build.credentials', 'Cust_00101', '{"given": false, "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (42, '2026-10-21 05:25:21.138859+00', 1, 'build.download', 'Cust_00101', '{"file": "001_client_init.sql", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (43, '2026-10-21 05:25:21.187051+00', 1, 'build.download', 'Cust_00101', '{"file": "docker-compose.yml", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (44, '2026-10-21 05:25:21.209423+00', 1, 'build.download', 'Cust_00101', '{"file": "README.md", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (45, '2026-10-21 05:25:21.251049+00', 1, 'build.download', 'Cust_00101', '{"file": "instance.json", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (46, '2026-10-21 05:25:21.266071+00', 1, 'build.download', 'Cust_00101', '{"file": "client_spec.json", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (47, '2026-10-21 05:25:21.297002+00', 1, 'build.download', 'Cust_00101', '{"file": "vciso-platform-cust_00101.tar.gz", "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (48, '2026-10-21 05:27:00.409627+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (49, '2026-10-21 05:27:00.426925+00', 1, 'build.start', 'Cust_00101', '{"version": 2, "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (50, '2026-10-21 05:27:09.044242+00', 1, 'build.success', 'Cust_00101', '{"users": 2, "version": 2, "build_id": "3", "image_tag": "cybertrustworks/vciso-platform:cust_00101-v2"}');
INSERT INTO public.ctw_audit_log VALUES (51, '2026-10-21 05:27:10.467556+00', 1, 'build.credentials', 'Cust_00101', '{"given": true, "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (52, '2026-10-21 05:27:10.48968+00', 1, 'build.download', 'Cust_00101', '{"file": "001_client_init.sql", "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (53, '2026-10-21 05:27:10.522255+00', 1, 'build.download', 'Cust_00101', '{"file": "docker-compose.yml", "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (54, '2026-10-21 05:27:10.554058+00', 1, 'build.download', 'Cust_00101', '{"file": "vciso-platform-cust_00101.tar.gz", "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (55, '2026-10-21 05:27:11.12143+00', 1, 'client.create', 'Cust_00808', '{}');
INSERT INTO public.ctw_audit_log VALUES (56, '2026-10-21 05:27:12.674549+00', 1, 'client.validate', 'Cust_00808', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (57, '2026-10-21 05:27:13.192745+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (58, '2026-10-21 05:27:13.206834+00', 1, 'build.start', 'Cust_00808', '{"version": 1, "build_id": "4"}');
INSERT INTO public.ctw_audit_log VALUES (59, '2026-10-21 05:27:13.507654+00', 1, 'build.failed', 'Cust_00808', '{"error": "bundle refused at validate: the specification is not valid: licensing_limits.valid_to (2025-01-01) is already in the past; licensing_limits.valid_to must be after contract_start_date (licence start)", "version": 1, "build_id": "4"}');
INSERT INTO public.ctw_audit_log VALUES (60, '2026-10-21 05:40:49.446635+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (61, '2026-10-21 05:40:52.14133+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (62, '2026-10-21 05:40:53.804776+00', 1, 'build.start', 'Cust_00101', '{"version": 3, "build_id": "6", "build_type": "image_only", "based_on_build": "3"}');
INSERT INTO public.ctw_audit_log VALUES (63, '2026-10-21 05:41:01.710472+00', 1, 'build.success', 'Cust_00101', '{"version": 3, "build_id": "6", "image_tag": "cybertrustworks/vciso-platform:cust_00101-v3", "build_type": "image_only"}');
INSERT INTO public.ctw_audit_log VALUES (64, '2026-10-21 05:41:01.933582+00', 1, 'build.credentials', 'Cust_00101', '{"given": false, "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (65, '2026-10-21 05:41:01.943787+00', 1, 'build.download', 'Cust_00101', '{"file": "docker-compose.yml", "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (66, '2026-10-21 05:41:01.958769+00', 1, 'build.download', 'Cust_00101', '{"file": "UPGRADE.md", "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (67, '2026-10-21 05:41:01.971777+00', 1, 'build.download', 'Cust_00101', '{"file": "vciso-platform-cust_00101.tar.gz", "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (68, '2026-10-21 05:41:02.60631+00', 1, 'build.download', 'Cust_00101', '{"file": "instance.json", "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (69, '2026-10-21 05:41:02.650553+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (70, '2026-10-21 05:41:03.673412+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (71, '2026-10-21 05:41:04.973424+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (72, '2026-10-21 05:41:05.711719+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (73, '2026-10-21 05:41:26.07175+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (74, '2026-10-21 05:41:26.841269+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (75, '2026-10-21 05:41:27.226288+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (76, '2026-10-21 05:41:28.170743+00', 1, 'client.update', 'Cust_00101', '{}');
INSERT INTO public.ctw_audit_log VALUES (77, '2026-10-21 05:41:29.264904+00', 1, 'client.validate', 'Cust_00101', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (78, '2026-10-21 05:42:03.679913+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (79, '2026-10-21 05:42:04.801243+00', 1, 'build.start', 'Cust_00101', '{"version": 4, "build_id": "7", "build_type": "full", "based_on_build": null}');
INSERT INTO public.ctw_audit_log VALUES (80, '2026-10-21 05:42:14.017944+00', 1, 'build.success', 'Cust_00101', '{"version": 4, "build_id": "7", "image_tag": "cybertrustworks/vciso-platform:cust_00101-v4", "build_type": "full"}');
INSERT INTO public.ctw_audit_log VALUES (81, '2026-10-21 05:42:15.124369+00', 1, 'build.credentials', 'Cust_00101', '{"given": true, "build_id": "7"}');
INSERT INTO public.ctw_audit_log VALUES (82, '2026-10-21 05:42:15.13457+00', 1, 'build.download', 'Cust_00101', '{"file": "vciso-platform-cust_00101.tar.gz", "build_id": "7"}');
INSERT INTO public.ctw_audit_log VALUES (83, '2026-10-21 05:42:16.452645+00', 1, 'build.start', 'Cust_00101', '{"version": 5, "build_id": "8", "build_type": "image_only", "based_on_build": "7"}');
INSERT INTO public.ctw_audit_log VALUES (84, '2026-10-21 05:42:23.873495+00', 1, 'build.success', 'Cust_00101', '{"version": 5, "build_id": "8", "image_tag": "cybertrustworks/vciso-platform:cust_00101-v5", "build_type": "image_only"}');
INSERT INTO public.ctw_audit_log VALUES (85, '2026-10-21 05:42:24.514968+00', 1, 'build.download', 'Cust_00101', '{"file": "UPGRADE.md", "build_id": "8"}');
INSERT INTO public.ctw_audit_log VALUES (86, '2026-10-21 05:42:48.376207+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (87, '2026-10-21 05:53:26.247841+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (88, '2026-10-21 05:53:27.45066+00', 1, 'client.create', 'Cust_00303', '{}');
INSERT INTO public.ctw_audit_log VALUES (89, '2026-10-21 05:53:30.016789+00', 1, 'client.validate', 'Cust_00303', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (90, '2026-10-21 05:53:30.742979+00', 1, 'build.start', 'Cust_00303', '{"version": 1, "build_id": "9", "build_type": "full", "based_on_build": null}');
INSERT INTO public.ctw_audit_log VALUES (91, '2026-10-21 05:53:40.326522+00', 1, 'build.success', 'Cust_00303', '{"version": 1, "build_id": "9", "image_tag": "cybertrustworks/vciso-platform:cust_00303-v1", "build_type": "full"}');
INSERT INTO public.ctw_audit_log VALUES (92, '2026-10-21 05:53:41.722502+00', 1, 'build.credentials', 'Cust_00303', '{"given": true, "build_id": "9"}');
INSERT INTO public.ctw_audit_log VALUES (93, '2026-10-21 05:53:43.200493+00', 1, 'build.credentials', 'Cust_00303', '{"given": false, "build_id": "9"}');
INSERT INTO public.ctw_audit_log VALUES (94, '2026-10-21 05:54:22.012024+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (95, '2026-10-21 05:54:49.268631+00', 1, 'admin.login', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (96, '2026-10-21 06:01:49.670939+00', 1, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (97, '2026-10-21 06:01:49.747422+00', 1, 'admin.mfa_enabled', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (98, '2026-10-21 06:01:49.901399+00', 1, 'admin.login', NULL, '{"mfa": true, "method": "totp"}');
INSERT INTO public.ctw_audit_log VALUES (99, '2026-10-21 06:01:49.977709+00', 1, 'admin.login', NULL, '{"mfa": true, "method": "recovery_code"}');
INSERT INTO public.ctw_audit_log VALUES (100, '2026-10-21 06:01:50.116165+00', 1, 'admin.create', NULL, '{"admin_id": 2, "login_id": "e2e.ops"}');
INSERT INTO public.ctw_audit_log VALUES (101, '2026-10-21 06:01:50.290197+00', 2, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (102, '2026-10-21 06:01:50.499543+00', 2, 'admin.password_change', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (103, '2026-10-21 06:01:50.537925+00', 1, 'admin.deactivate', NULL, '{"admin_id": 2, "login_id": "e2e.ops"}');
INSERT INTO public.ctw_audit_log VALUES (104, '2026-10-21 06:01:50.674505+00', 1, 'admin.reset_password', NULL, '{"admin_id": 2, "login_id": "e2e.ops"}');
INSERT INTO public.ctw_audit_log VALUES (105, '2026-10-21 06:01:50.689069+00', 1, 'admin.reset_mfa', NULL, '{"admin_id": 2, "login_id": "e2e.ops"}');
INSERT INTO public.ctw_audit_log VALUES (106, '2026-10-21 06:01:50.788087+00', 1, 'build.files_removed', 'Cust_00101', '{"freed": 64148708, "version": 1, "build_id": "2"}');
INSERT INTO public.ctw_audit_log VALUES (107, '2026-10-21 06:01:50.831965+00', 1, 'build.files_removed', 'Cust_00101', '{"freed": 64148598, "version": 2, "build_id": "3"}');
INSERT INTO public.ctw_audit_log VALUES (108, '2026-10-21 06:01:50.841783+00', 1, 'build.files_removed', 'Cust_00101', '{"freed": 63930377, "version": 3, "build_id": "6"}');
INSERT INTO public.ctw_audit_log VALUES (109, '2026-10-21 06:01:53.88331+00', 1, 'admin.logout_all', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (110, '2026-10-21 06:05:06.159098+00', NULL, 'admin.reset_mfa', NULL, '{"by": "phase 8 test cleanup", "login_id": "ctw.admin"}');
INSERT INTO public.ctw_audit_log VALUES (111, '2026-10-21 06:06:22.368119+00', 1, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (112, '2026-10-21 06:06:23.924645+00', 1, 'admin.mfa_enabled', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (113, '2026-10-21 06:06:25.76607+00', 1, 'admin.create', NULL, '{"admin_id": 4, "login_id": "ui.tester"}');
INSERT INTO public.ctw_audit_log VALUES (118, '2026-10-21 06:07:20.680096+00', 1, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (119, '2026-10-21 06:07:21.881283+00', 1, 'admin.mfa_enabled', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (120, '2026-10-21 06:07:23.561117+00', 1, 'admin.create', NULL, '{"admin_id": 5, "login_id": "ui.tester"}');
INSERT INTO public.ctw_audit_log VALUES (121, '2026-10-21 06:07:24.801964+00', 5, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (122, '2026-10-21 06:07:25.097742+00', 5, 'admin.password_change', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (123, '2026-10-21 06:07:25.622332+00', 5, 'admin.mfa_enabled', NULL, '{}');
INSERT INTO public.ctw_audit_log VALUES (124, '2026-10-21 06:07:27.029693+00', 5, 'admin.login', NULL, '{"mfa": true, "method": "totp"}');
INSERT INTO public.ctw_audit_log VALUES (125, '2026-10-21 06:07:28.050991+00', 1, 'admin.login', NULL, '{"mfa": true, "method": "recovery_code"}');
INSERT INTO public.ctw_audit_log VALUES (126, '2026-10-21 06:07:28.925784+00', 1, 'admin.deactivate', NULL, '{"admin_id": 5, "login_id": "ui.tester"}');
INSERT INTO public.ctw_audit_log VALUES (127, '2026-10-21 06:07:56.319686+00', NULL, 'admin.reset_mfa', NULL, '{"by": "phase 8 test cleanup", "login_id": "ctw.admin"}');
INSERT INTO public.ctw_audit_log VALUES (128, '2026-10-21 06:51:04.271096+00', NULL, 'admin.create', NULL, '{"by": "created in the database on request", "admin_id": 6, "login_id": "anujvmahajan"}');
INSERT INTO public.ctw_audit_log VALUES (129, '2026-10-21 06:51:04.564007+00', NULL, 'admin.login', NULL, '{"mfa": false, "admin_login": "anujvmahajan"}');
INSERT INTO public.ctw_audit_log VALUES (130, '2026-10-21 06:53:54.199716+00', NULL, 'admin.delete', NULL, '{"by": "removed in the database on request", "login_id": "anujvmahajan"}');
INSERT INTO public.ctw_audit_log VALUES (131, '2026-10-21 06:53:54.199716+00', NULL, 'admin.create', NULL, '{"by": "created in the database on request", "login_id": "anish"}');
INSERT INTO public.ctw_audit_log VALUES (132, '2026-10-21 06:53:54.639494+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (133, '2026-10-21 06:53:54.996933+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (134, '2026-10-21 06:55:36.112834+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (135, '2026-10-21 06:55:36.940876+00', 1, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (136, '2026-10-21 07:05:11.464223+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (137, '2026-10-21 07:06:12.068381+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (138, '2026-10-21 07:06:39.272118+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (139, '2026-10-21 08:19:39.566057+00', NULL, 'admin.update', NULL, '{"by": "changed in the database on request", "email": "anish@gmail.com", "login_id": "anish"}');
INSERT INTO public.ctw_audit_log VALUES (140, '2026-10-21 08:19:57.321599+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (141, '2026-10-21 08:21:06.267395+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (142, '2026-10-21 10:48:31.543025+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (143, '2026-10-21 10:50:53.561257+00', 7, 'client.create', 'Cust_00202', '{}');
INSERT INTO public.ctw_audit_log VALUES (144, '2026-10-21 11:15:56.776699+00', 7, 'client.create', 'Cust_00206', '{}');
INSERT INTO public.ctw_audit_log VALUES (145, '2026-10-21 11:17:25.557251+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (146, '2026-10-21 11:17:48.550556+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (147, '2026-10-21 11:20:01.540013+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (148, '2026-10-21 11:20:03.337526+00', 7, 'client.validate', 'Cust_00206', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (149, '2026-10-21 11:20:04.43366+00', 7, 'client.validate', 'Cust_00202', '{"valid": false, "errors": 3}');
INSERT INTO public.ctw_audit_log VALUES (150, '2026-10-21 11:49:22.19867+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (151, '2026-10-21 11:55:01.652254+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (152, '2026-10-21 11:56:07.701084+00', 7, 'build.start', 'Cust_00206', '{"version": 1, "build_id": "10", "build_type": "full", "based_on_build": null}');
INSERT INTO public.ctw_audit_log VALUES (153, '2026-10-21 11:56:16.552336+00', 7, 'build.success', 'Cust_00206', '{"version": 1, "build_id": "10", "image_tag": "cybertrustworks/vciso-platform:cust_00206-v1", "build_type": "full"}');
INSERT INTO public.ctw_audit_log VALUES (154, '2026-10-21 11:56:32.268199+00', 7, 'build.credentials', 'Cust_00206', '{"given": true, "build_id": "10"}');
INSERT INTO public.ctw_audit_log VALUES (155, '2026-10-21 11:58:27.726327+00', 7, 'build.credentials', 'Cust_00206', '{"given": false, "build_id": "10"}');
INSERT INTO public.ctw_audit_log VALUES (156, '2026-10-21 12:38:18.813059+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (157, '2026-10-21 13:15:54.704232+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (158, '2026-10-21 13:49:43.267513+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (159, '2026-10-21 13:52:09.426715+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (160, '2026-10-21 14:01:05.247569+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (161, '2026-10-21 14:19:39.017983+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (162, '2026-10-21 14:27:26.234337+00', 7, 'client.create', 'Cust_00210', '{}');
INSERT INTO public.ctw_audit_log VALUES (163, '2026-10-21 14:31:25.835873+00', 7, 'client.update', 'Cust_00210', '{}');
INSERT INTO public.ctw_audit_log VALUES (164, '2026-10-21 14:38:20.746753+00', 7, 'client.update', 'Cust_00210', '{}');
INSERT INTO public.ctw_audit_log VALUES (165, '2026-10-21 14:40:34.110102+00', 7, 'client.update', 'Cust_00210', '{}');
INSERT INTO public.ctw_audit_log VALUES (166, '2026-10-21 14:40:36.811824+00', 7, 'client.update', 'Cust_00210', '{}');
INSERT INTO public.ctw_audit_log VALUES (167, '2026-10-21 14:40:37.731002+00', 7, 'client.validate', 'Cust_00210', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (168, '2026-10-21 14:41:06.093345+00', 7, 'build.start', 'Cust_00210', '{"version": 1, "build_id": "11", "build_type": "full", "based_on_build": null}');
INSERT INTO public.ctw_audit_log VALUES (169, '2026-10-21 14:41:34.067895+00', 7, 'build.success', 'Cust_00210', '{"version": 1, "build_id": "11", "image_tag": "cybertrustworks/vciso-platform:cust_00210-v1", "build_type": "full"}');
INSERT INTO public.ctw_audit_log VALUES (170, '2026-10-21 14:41:40.971603+00', 7, 'build.credentials', 'Cust_00210', '{"given": true, "build_id": "11"}');
INSERT INTO public.ctw_audit_log VALUES (171, '2026-10-21 16:07:30.497649+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (172, '2026-10-21 16:16:44.561983+00', 7, 'client.create', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (173, '2026-10-21 16:16:46.88311+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (174, '2026-10-21 16:16:47.419755+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 16}');
INSERT INTO public.ctw_audit_log VALUES (175, '2026-10-21 16:44:38.71545+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (176, '2026-10-21 16:44:39.390634+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 4}');
INSERT INTO public.ctw_audit_log VALUES (177, '2026-10-21 16:45:05.484354+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (178, '2026-10-21 16:45:05.877659+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 3}');
INSERT INTO public.ctw_audit_log VALUES (179, '2026-10-21 16:45:26.07974+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (180, '2026-10-21 16:45:26.408902+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 3}');
INSERT INTO public.ctw_audit_log VALUES (181, '2026-10-21 16:45:28.704728+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (182, '2026-10-21 16:45:29.050164+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 3}');
INSERT INTO public.ctw_audit_log VALUES (183, '2026-10-21 16:45:57.341078+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (184, '2026-10-21 16:45:57.670717+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 2}');
INSERT INTO public.ctw_audit_log VALUES (185, '2026-10-21 16:46:12.854492+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (186, '2026-10-21 16:46:13.185618+00', 7, 'client.validate', 'Cust_00215', '{"valid": false, "errors": 1}');
INSERT INTO public.ctw_audit_log VALUES (187, '2026-10-21 16:46:48.132986+00', 7, 'client.update', 'Cust_00215', '{}');
INSERT INTO public.ctw_audit_log VALUES (188, '2026-10-21 16:46:48.437053+00', 7, 'client.validate', 'Cust_00215', '{"valid": true, "errors": 0}');
INSERT INTO public.ctw_audit_log VALUES (189, '2026-10-21 16:47:26.237355+00', 7, 'build.start', 'Cust_00215', '{"version": 1, "build_id": "12", "build_type": "full", "based_on_build": null}');
INSERT INTO public.ctw_audit_log VALUES (190, '2026-10-21 16:47:35.866685+00', 7, 'build.success', 'Cust_00215', '{"version": 1, "build_id": "12", "image_tag": "cybertrustworks/vciso-platform:cust_00215-v1", "build_type": "full"}');
INSERT INTO public.ctw_audit_log VALUES (191, '2026-10-21 16:48:18.655982+00', 7, 'build.download', 'Cust_00215', '{"file": "001_client_init.sql", "build_id": "12"}');
INSERT INTO public.ctw_audit_log VALUES (192, '2026-10-21 18:14:35.330169+00', 7, 'admin.login', NULL, '{"mfa": false}');
INSERT INTO public.ctw_audit_log VALUES (193, '2026-10-21 18:15:55.130212+00', 7, 'admin.login', NULL, '{"mfa": false}');


--
-- Data for Name: ctw_build; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_build VALUES (2, 'Cust_00101', 1, 'full', NULL, 'success', '91cf2820-2e7d-4521-8f0c-22b19d33974f', '577d04176afe943249794bf4ed0b9c2587065d8920b4fe1becea9e65077d804e', 'cybertrustworks/vciso-platform:cust_00101-v1', 63914904, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v1', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 1200000, "financial_year": 2026, "customer_ref_po": "PO_ACME_2026_09", "contract_end_date": "2027-03-31", "contract_start_date": "2026-04-01", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "https://cloud.tenable.com", "pull_frequency_per_day": 2}, {"enabled": true, "tool_name": "Greenbone", "target_endpoint": "https://scanner.internal.acmefinance.com:9390", "pull_frequency_per_day": 1}]}, "organization": {"offices": [{"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400051", "office_id": "Cust_00101_001", "office_type": "Primary", "office_address": "Tower 4, Bandra Kurla Complex"}, {"city": "London", "state": "Greater London", "country": "United Kingdom", "pincode": "EC2M 5TN", "office_id": "Cust_00101_002", "office_type": "Secondary", "office_address": "77 London Wall"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0001", "department": "Executive Board", "designation": "Chief Technology & Risk Officer", "contact_type": "Executive", "contact_email": "v.malhotra@acmefinance.com", "contact_phone": "+91-98200-11223", "contact_person": "Vikram Malhotra", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0002", "department": "Information Security", "designation": "Head of Information Security / vCISO", "contact_type": "Primary vCISO", "contact_email": "priya.sharma@acmefinance.com", "contact_phone": "+91-98200-33445", "contact_person": "Priya Sharma", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0003", "department": "IT Operations", "designation": "Security Operations Lead", "contact_type": "Escalation", "contact_email": "rohan.gupta@acmefinance.com", "contact_phone": "+91-98200-55667", "contact_person": "Rohan Gupta", "contact_priority": 2}], "industry": "Banking & Financial Services", "customer_id": "Cust_00101", "customer_name": "Acme Financial Services International Ltd.", "primary_domain": "acmefinance.com", "deployment_fqdn": "vciso.acmefinance.com"}, "initial_users": [{"user_id": "User_0001", "login_id": "priya.sharma", "office_id": "Cust_00101_001", "role_type": "vCISO", "user_name": "Priya Sharma", "department": "Information Security", "user_email": "priya.sharma@acmefinance.com", "designation": "vCISO", "user_mobile": "+91-98200-33445"}, {"user_id": "User_0002", "login_id": "vikram.malhotra", "office_id": "Cust_00101_001", "role_type": "Organisation Owner", "user_name": "Vikram Malhotra", "department": "Executive Board", "user_email": "v.malhotra@acmefinance.com", "designation": "CTO & Risk Officer", "user_mobile": "+91-98200-11223"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "mobile_access", "news_breach_watch", "incidents"], "licensing_limits": {"valid_to": "2027-03-31", "max_users": 25, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 20, "max_api_integrations": 10}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": true, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["Fintech leak", "Acme core banking"], "monitored_names": ["Acme Financial", "Acme Financial Services", "Acme International Bank"], "monitored_cities": ["Mumbai", "London", "Bengaluru"], "monitored_domains": ["acmefinance.com", "acmebank.co.in", "secure.acmefinance.com"]}, "selected_frameworks": [{"office_ids": ["Cust_00101_001", "Cust_00101_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00101_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v1 of Cust_00101 (build 2), image cybertrustworks/vciso-platform:cust_00101-v1

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for: Acme Financial Services International Ltd.
     Customer ID: Cust_00101
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed 577d04176afe9432...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00101\v1\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''incidents'', ''mobile_access'', ''news_breach_watch'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v1\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v1\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v1\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v1\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
   done in 0.4s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 1.2s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [builder 2/8] WORKDIR /app
   #6 CACHED
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #8 CACHED
   
   #9 [context instance] load from client
   #9 transferring instance: 606B 0.0s done
   #9 DONE 0.0s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.0s
   
   #11 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #11 0.222 Building for Cust_00101 (instance 91cf2820-2e7d-4521-8f0c-22b19d33974f), modules: alerting, compliance, incidents, mobile_access, news_breach_watch, vulnerabilities
   #11 DONE 0.2s
   
   #12 [builder 5/8] COPY src ./src
   #12 CACHED
   
   #13 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #13 CACHED
   
   #14 [builder 4/8] RUN npm ci
   #14 CACHED
   
   #15 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #15 CACHED
   
   #16 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #16 CACHED
   
   #17 [ui 4/6] RUN npm ci
   #17 CACHED
   
   #18 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #18 CACHED
   
   #19 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #19 CACHED
   
   #20 [ui 2/6] WORKDIR /ui
   #20 CACHED
   
   #21 [ui 6/6] RUN npm run build
   #21 CACHED
   
   #22 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #22 0.826 (1/1) Installing tini (0.19.0-r3)
   #22 0.857 Executing busybox-1.37.0-r31.trigger
   #22 0.865 OK: 10.9 MiB in 20 packages
   #22 DONE 0.9s
   
   #23 [production 3/8] WORKDIR /app
   #23 DONE 0.0s
   
   #24 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #24 DONE 0.1s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.0s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.0s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:494f553f7aa5a4d2762acd73342c70fc67531316b984a7e3ca631e20b4a8a6f5 0.0s done
   #29 exporting config sha256:0c7f2ca8035a9128da6259c142fbf2f8880e443a9aab2a39b933beeb70d95990 0.0s done
   #29 exporting attestation manifest sha256:287e8a7913d04cb45617ee6f7e2759ec5de1c7f3d6574d5056ef0d8a85843249 0.0s done
   #29 exporting manifest list sha256:c7e3b2bed2bea88a03ac8f3d28609171519d24cf68328a3a21d6e3c4a5821d3e done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00101-v1 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v1
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v1 0.2s done
   #29 DONE 0.5s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/qumasbnvycr19quq08op03glj
   done in 3.6s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00101.tar.gz: 61.0 MB
   done in 4.9s

SUCCESS: cybertrustworks/vciso-platform:cust_00101-v1, instance 91cf2820-2e7d-4521-8f0c-22b19d33974f
', NULL, 1, '2026-10-21 05:25:10.782579+00', '2026-10-21 05:25:10.794229+00', '2026-10-21 05:25:19.809037+00', '2026-10-21 06:01:50.784419+00');
INSERT INTO public.ctw_build VALUES (3, 'Cust_00101', 2, 'full', NULL, 'success', '82bb6989-6050-4c86-affe-533961a7df8c', '577d04176afe943249794bf4ed0b9c2587065d8920b4fe1becea9e65077d804e', 'cybertrustworks/vciso-platform:cust_00101-v2', 63914619, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v2', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 1200000, "financial_year": 2026, "customer_ref_po": "PO_ACME_2026_09", "contract_end_date": "2027-03-31", "contract_start_date": "2026-04-01", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "https://cloud.tenable.com", "pull_frequency_per_day": 2}, {"enabled": true, "tool_name": "Greenbone", "target_endpoint": "https://scanner.internal.acmefinance.com:9390", "pull_frequency_per_day": 1}]}, "organization": {"offices": [{"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400051", "office_id": "Cust_00101_001", "office_type": "Primary", "office_address": "Tower 4, Bandra Kurla Complex"}, {"city": "London", "state": "Greater London", "country": "United Kingdom", "pincode": "EC2M 5TN", "office_id": "Cust_00101_002", "office_type": "Secondary", "office_address": "77 London Wall"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0001", "department": "Executive Board", "designation": "Chief Technology & Risk Officer", "contact_type": "Executive", "contact_email": "v.malhotra@acmefinance.com", "contact_phone": "+91-98200-11223", "contact_person": "Vikram Malhotra", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0002", "department": "Information Security", "designation": "Head of Information Security / vCISO", "contact_type": "Primary vCISO", "contact_email": "priya.sharma@acmefinance.com", "contact_phone": "+91-98200-33445", "contact_person": "Priya Sharma", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0003", "department": "IT Operations", "designation": "Security Operations Lead", "contact_type": "Escalation", "contact_email": "rohan.gupta@acmefinance.com", "contact_phone": "+91-98200-55667", "contact_person": "Rohan Gupta", "contact_priority": 2}], "industry": "Banking & Financial Services", "customer_id": "Cust_00101", "customer_name": "Acme Financial Services International Ltd.", "primary_domain": "acmefinance.com", "deployment_fqdn": "vciso.acmefinance.com"}, "initial_users": [{"user_id": "User_0001", "login_id": "priya.sharma", "office_id": "Cust_00101_001", "role_type": "vCISO", "user_name": "Priya Sharma", "department": "Information Security", "user_email": "priya.sharma@acmefinance.com", "designation": "vCISO", "user_mobile": "+91-98200-33445"}, {"user_id": "User_0002", "login_id": "vikram.malhotra", "office_id": "Cust_00101_001", "role_type": "Organisation Owner", "user_name": "Vikram Malhotra", "department": "Executive Board", "user_email": "v.malhotra@acmefinance.com", "designation": "CTO & Risk Officer", "user_mobile": "+91-98200-11223"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "mobile_access", "news_breach_watch", "incidents"], "licensing_limits": {"valid_to": "2027-03-31", "max_users": 25, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 20, "max_api_integrations": 10}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": true, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["Fintech leak", "Acme core banking"], "monitored_names": ["Acme Financial", "Acme Financial Services", "Acme International Bank"], "monitored_cities": ["Mumbai", "London", "Bengaluru"], "monitored_domains": ["acmefinance.com", "acmebank.co.in", "secure.acmefinance.com"]}, "selected_frameworks": [{"office_ids": ["Cust_00101_001", "Cust_00101_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00101_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v2 of Cust_00101 (build 3), image cybertrustworks/vciso-platform:cust_00101-v2

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for: Acme Financial Services International Ltd.
     Customer ID: Cust_00101
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed 577d04176afe9432...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00101\v2\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''incidents'', ''mobile_access'', ''news_breach_watch'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v2\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v2\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v2\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v2\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
   done in 0.5s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 0.9s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [builder 2/8] WORKDIR /app
   #6 CACHED
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #8 CACHED
   
   #9 [context instance] load from client
   #9 transferring instance: 606B 0.0s done
   #9 DONE 0.0s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.0s
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 ...
   
   #12 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #12 0.310 Building for Cust_00101 (instance 82bb6989-6050-4c86-affe-533961a7df8c), modules: alerting, compliance, incidents, mobile_access, news_breach_watch, vulnerabilities
   #12 DONE 0.3s
   
   #13 [builder 4/8] RUN npm ci
   #13 CACHED
   
   #14 [builder 5/8] COPY src ./src
   #14 CACHED
   
   #15 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #15 CACHED
   
   #16 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #16 CACHED
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 CACHED
   
   #18 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #18 CACHED
   
   #19 [ui 2/6] WORKDIR /ui
   #19 CACHED
   
   #20 [ui 4/6] RUN npm ci
   #20 CACHED
   
   #21 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #21 CACHED
   
   #22 [ui 6/6] RUN npm run build
   #22 CACHED
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 0.742 (1/1) Installing tini (0.19.0-r3)
   #11 0.754 Executing busybox-1.37.0-r31.trigger
   #11 0.759 OK: 10.9 MiB in 20 packages
   #11 DONE 0.8s
   
   #23 [production 3/8] WORKDIR /app
   #23 DONE 0.0s
   
   #24 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #24 DONE 0.2s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.0s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.0s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.3s done
   #29 exporting manifest sha256:d9fdf85267002a19b52301eee622ae5912832874cd9265386bc689c5480849ee 0.0s done
   #29 exporting config sha256:c67dd7477e3b474cdf422fd54fc080112d8d58932068b8c63a82a1d0cb81f316 0.0s done
   #29 exporting attestation manifest sha256:ce6e8ac2b2e5604de610af22d052253758209774793c476a7b2bf0e9672329f1 0.0s done
   #29 exporting manifest list sha256:9e76acfbfb6d5e51273120f15573133780dbf6701f4e456cfd9540ccd3a948e7 done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00101-v2 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v2
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v2 0.2s done
   #29 DONE 0.6s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/n79j11xkx2kwg47iu8s3yo2n5
   done in 3.3s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00101.tar.gz: 61.0 MB
   done in 4.8s

SUCCESS: cybertrustworks/vciso-platform:cust_00101-v2, instance 82bb6989-6050-4c86-affe-533961a7df8c
', NULL, 1, '2026-10-21 05:27:00.420172+00', '2026-10-21 05:27:00.430156+00', '2026-10-21 05:27:09.039233+00', '2026-10-21 06:01:50.828746+00');
INSERT INTO public.ctw_build VALUES (6, 'Cust_00101', 3, 'image_only', 3, 'success', '82bb6989-6050-4c86-affe-533961a7df8c', '577d04176afe943249794bf4ed0b9c2587065d8920b4fe1becea9e65077d804e', 'cybertrustworks/vciso-platform:cust_00101-v3', 63914697, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v3', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 1200000, "financial_year": 2026, "customer_ref_po": "PO_ACME_2026_09", "contract_end_date": "2027-03-31", "contract_start_date": "2026-04-01", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "https://cloud.tenable.com", "pull_frequency_per_day": 2}, {"enabled": true, "tool_name": "Greenbone", "target_endpoint": "https://scanner.internal.acmefinance.com:9390", "pull_frequency_per_day": 1}]}, "organization": {"offices": [{"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400051", "office_id": "Cust_00101_001", "office_type": "Primary", "office_address": "Tower 4, Bandra Kurla Complex"}, {"city": "London", "state": "Greater London", "country": "United Kingdom", "pincode": "EC2M 5TN", "office_id": "Cust_00101_002", "office_type": "Secondary", "office_address": "77 London Wall"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0001", "department": "Executive Board", "designation": "Chief Technology & Risk Officer", "contact_type": "Executive", "contact_email": "v.malhotra@acmefinance.com", "contact_phone": "+91-98200-11223", "contact_person": "Vikram Malhotra", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0002", "department": "Information Security", "designation": "Head of Information Security / vCISO", "contact_type": "Primary vCISO", "contact_email": "priya.sharma@acmefinance.com", "contact_phone": "+91-98200-33445", "contact_person": "Priya Sharma", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0003", "department": "IT Operations", "designation": "Security Operations Lead", "contact_type": "Escalation", "contact_email": "rohan.gupta@acmefinance.com", "contact_phone": "+91-98200-55667", "contact_person": "Rohan Gupta", "contact_priority": 2}], "industry": "Banking & Financial Services", "customer_id": "Cust_00101", "customer_name": "Acme Financial Services International Ltd.", "primary_domain": "acmefinance.com", "deployment_fqdn": "vciso.acmefinance.com"}, "initial_users": [{"user_id": "User_0001", "login_id": "priya.sharma", "office_id": "Cust_00101_001", "role_type": "vCISO", "user_name": "Priya Sharma", "department": "Information Security", "user_email": "priya.sharma@acmefinance.com", "designation": "vCISO", "user_mobile": "+91-98200-33445"}, {"user_id": "User_0002", "login_id": "vikram.malhotra", "office_id": "Cust_00101_001", "role_type": "Organisation Owner", "user_name": "Vikram Malhotra", "department": "Executive Board", "user_email": "v.malhotra@acmefinance.com", "designation": "CTO & Risk Officer", "user_mobile": "+91-98200-11223"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "mobile_access", "news_breach_watch", "incidents"], "licensing_limits": {"valid_to": "2027-03-31", "max_users": 25, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 20, "max_api_integrations": 10}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": true, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["Fintech leak", "Acme core banking"], "monitored_names": ["Acme Financial", "Acme Financial Services", "Acme International Bank"], "monitored_cities": ["Mumbai", "London", "Bengaluru"], "monitored_domains": ["acmefinance.com", "acmebank.co.in", "secure.acmefinance.com"]}, "selected_frameworks": [{"office_ids": ["Cust_00101_001", "Cust_00101_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00101_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v3 of Cust_00101 (build 6, image_only), image cybertrustworks/vciso-platform:cust_00101-v3

== 1/3 Instance of the base build
   instance 82bb6989-6050-4c86-affe-533961a7df8c from v2; the client''s database is kept
   note: not in this update (needs a full build): organisation, offices and contacts
   note: not in this update (needs a full build): contract
   note: not in this update (needs a full build): licence limits
   note: not in this update (needs a full build): frameworks and their offices
   note: not in this update (needs a full build): tool integrations
   note: not in this update (needs a full build): news watch profile
   note: not in this update (needs a full build): initial users
   done in 0.0s

== 2/3 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 1.2s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [builder 2/8] WORKDIR /app
   #6 CACHED
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [context instance] load from client
   #8 transferring instance: 35B done
   #8 DONE 0.0s
   
   #9 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #9 CACHED
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 CACHED
   
   #11 [builder 4/8] RUN npm ci
   #11 CACHED
   
   #12 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #12 CACHED
   
   #13 [builder 5/8] COPY src ./src
   #13 CACHED
   
   #14 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #14 CACHED
   
   #15 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #15 CACHED
   
   #16 [ui 2/6] WORKDIR /ui
   #16 CACHED
   
   #17 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #17 CACHED
   
   #18 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #18 CACHED
   
   #19 [ui 4/6] RUN npm ci
   #19 CACHED
   
   #20 [ui 6/6] RUN npm run build
   #20 CACHED
   
   #21 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #21 CACHED
   
   #22 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #22 0.966 (1/1) Installing tini (0.19.0-r3)
   #22 0.976 Executing busybox-1.37.0-r31.trigger
   #22 0.982 OK: 10.9 MiB in 20 packages
   #22 DONE 1.0s
   
   #23 [production 3/8] WORKDIR /app
   #23 DONE 0.0s
   
   #24 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #24 DONE 0.1s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.0s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.0s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:29a02f7f0ed6a6126378736a5963b04f0cd42e0fc4530eab5c5db6192b78569b done
   #29 exporting config sha256:a8677b4e163f522760f8969cd537a53cbcab33872296e4f55dc9e43730fc1e37 done
   #29 exporting attestation manifest sha256:f8bf090994d4410b7d1c4ccdfec8da4620cf3ecbe292d50b051d2c07e29f29f9 0.0s done
   #29 exporting manifest list sha256:1ae6f0fa4f4d080ac7b0bf0c7737abb97607d83ab7c1d801b648d44f9707022b 0.0s done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00101-v3 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v3
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v3 0.2s done
   #29 DONE 0.6s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/zhzr2wrzrwzf93ulckoa5oryl
   done in 3.9s

== 3/3 Image file (docker save | gzip)
   vciso-platform-cust_00101.tar.gz: 61.0 MB
   done in 4.0s

SUCCESS: cybertrustworks/vciso-platform:cust_00101-v3, instance 82bb6989-6050-4c86-affe-533961a7df8c
', NULL, 1, '2026-10-21 05:40:53.797531+00', '2026-10-21 05:40:53.809289+00', '2026-10-21 05:41:01.706273+00', '2026-10-21 06:01:50.839371+00');
INSERT INTO public.ctw_build VALUES (8, 'Cust_00101', 5, 'image_only', 7, 'success', '65cdf08b-115a-49cc-9f06-66ea535c1111', '577d04176afe943249794bf4ed0b9c2587065d8920b4fe1becea9e65077d804e', 'cybertrustworks/vciso-platform:cust_00101-v5', 63914465, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v5', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 1200000, "financial_year": 2026, "customer_ref_po": "PO_ACME_2026_09", "contract_end_date": "2027-03-31", "contract_start_date": "2026-04-01", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "https://cloud.tenable.com", "pull_frequency_per_day": 2}, {"enabled": true, "tool_name": "Greenbone", "target_endpoint": "https://scanner.internal.acmefinance.com:9390", "pull_frequency_per_day": 1}]}, "organization": {"offices": [{"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400051", "office_id": "Cust_00101_001", "office_type": "Primary", "office_address": "Tower 4, Bandra Kurla Complex"}, {"city": "London", "state": "Greater London", "country": "United Kingdom", "pincode": "EC2M 5TN", "office_id": "Cust_00101_002", "office_type": "Secondary", "office_address": "77 London Wall"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0001", "department": "Executive Board", "designation": "Chief Technology & Risk Officer", "contact_type": "Executive", "contact_email": "v.malhotra@acmefinance.com", "contact_phone": "+91-98200-11223", "contact_person": "Vikram Malhotra", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0002", "department": "Information Security", "designation": "Head of Information Security / vCISO", "contact_type": "Primary vCISO", "contact_email": "priya.sharma@acmefinance.com", "contact_phone": "+91-98200-33445", "contact_person": "Priya Sharma", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0003", "department": "IT Operations", "designation": "Security Operations Lead", "contact_type": "Escalation", "contact_email": "rohan.gupta@acmefinance.com", "contact_phone": "+91-98200-55667", "contact_person": "Rohan Gupta", "contact_priority": 2}], "industry": "Banking & Financial Services", "customer_id": "Cust_00101", "customer_name": "Acme Financial Services International Ltd.", "primary_domain": "acmefinance.com", "deployment_fqdn": "vciso.acmefinance.com"}, "initial_users": [{"user_id": "User_0001", "login_id": "priya.sharma", "office_id": "Cust_00101_001", "role_type": "vCISO", "user_name": "Priya Sharma", "department": "Information Security", "user_email": "priya.sharma@acmefinance.com", "designation": "vCISO", "user_mobile": "+91-98200-33445"}, {"user_id": "User_0002", "login_id": "vikram.malhotra", "office_id": "Cust_00101_001", "role_type": "Organisation Owner", "user_name": "Vikram Malhotra", "department": "Executive Board", "user_email": "v.malhotra@acmefinance.com", "designation": "CTO & Risk Officer", "user_mobile": "+91-98200-11223"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "mobile_access", "news_breach_watch", "incidents"], "licensing_limits": {"valid_to": "2027-03-31", "max_users": 25, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 20, "max_api_integrations": 10}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": true, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["Fintech leak", "Acme core banking"], "monitored_names": ["Acme Financial", "Acme Financial Services", "Acme International Bank"], "monitored_cities": ["Mumbai", "London", "Bengaluru"], "monitored_domains": ["acmefinance.com", "acmebank.co.in", "secure.acmefinance.com"]}, "selected_frameworks": [{"office_ids": ["Cust_00101_001", "Cust_00101_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00101_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v5 of Cust_00101 (build 8, image_only), image cybertrustworks/vciso-platform:cust_00101-v5

== 1/3 Instance of the base build
   instance 65cdf08b-115a-49cc-9f06-66ea535c1111 from v4; the client''s database is kept
   done in 0.0s

== 2/3 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 0.4s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [context instance] load from client
   #6 transferring instance: 35B done
   #6 DONE 0.0s
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [builder 2/8] WORKDIR /app
   #8 CACHED
   
   #9 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #9 CACHED
   
   #10 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #10 CACHED
   
   #11 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #11 CACHED
   
   #12 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #12 CACHED
   
   #13 [builder 4/8] RUN npm ci
   #13 CACHED
   
   #14 [builder 5/8] COPY src ./src
   #14 CACHED
   
   #15 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #15 CACHED
   
   #16 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #16 CACHED
   
   #17 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #17 CACHED
   
   #18 [ui 4/6] RUN npm ci
   #18 CACHED
   
   #19 [ui 2/6] WORKDIR /ui
   #19 CACHED
   
   #20 [ui 6/6] RUN npm run build
   #20 CACHED
   
   #21 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #21 CACHED
   
   #22 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #22 0.879 (1/1) Installing tini (0.19.0-r3)
   #22 0.895 Executing busybox-1.37.0-r31.trigger
   #22 0.904 OK: 10.9 MiB in 20 packages
   #22 DONE 1.0s
   
   #23 [production 3/8] WORKDIR /app
   #23 DONE 0.0s
   
   #24 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #24 DONE 0.2s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.1s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.1s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.1s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.3s done
   #29 exporting manifest sha256:936d4a889e7b692cb22f622bc99a67d92c9ae3eaed78b071fa1566b350abd91b 0.0s done
   #29 exporting config sha256:e97787efe2f29645f43086b7f8b009111facd2a0c11f971f9570375942f8f10a done
   #29 exporting attestation manifest sha256:71ef609d44c61f1ce223d03a57a903869f8455614f48804cc3f707b0f15c2791 0.0s done
   #29 exporting manifest list sha256:4d66718f429229e870bb0bb0b85bdcc1fc25f9c6de6c7b587f6d315e93dfba13 done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00101-v5 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v5
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v5 0.3s done
   #29 DONE 0.6s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/zfyo62zybgos9uj346ksdpnie
   done in 3.1s

== 3/3 Image file (docker save | gzip)
   vciso-platform-cust_00101.tar.gz: 61.0 MB
   done in 4.3s

SUCCESS: cybertrustworks/vciso-platform:cust_00101-v5, instance 65cdf08b-115a-49cc-9f06-66ea535c1111
', NULL, 1, '2026-10-21 05:42:16.443264+00', '2026-10-21 05:42:16.458163+00', '2026-10-21 05:42:23.868664+00', NULL);
INSERT INTO public.ctw_build VALUES (7, 'Cust_00101', 4, 'full', NULL, 'success', '65cdf08b-115a-49cc-9f06-66ea535c1111', '577d04176afe943249794bf4ed0b9c2587065d8920b4fe1becea9e65077d804e', 'cybertrustworks/vciso-platform:cust_00101-v4', 63914829, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v4', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 1200000, "financial_year": 2026, "customer_ref_po": "PO_ACME_2026_09", "contract_end_date": "2027-03-31", "contract_start_date": "2026-04-01", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "https://cloud.tenable.com", "pull_frequency_per_day": 2}, {"enabled": true, "tool_name": "Greenbone", "target_endpoint": "https://scanner.internal.acmefinance.com:9390", "pull_frequency_per_day": 1}]}, "organization": {"offices": [{"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400051", "office_id": "Cust_00101_001", "office_type": "Primary", "office_address": "Tower 4, Bandra Kurla Complex"}, {"city": "London", "state": "Greater London", "country": "United Kingdom", "pincode": "EC2M 5TN", "office_id": "Cust_00101_002", "office_type": "Secondary", "office_address": "77 London Wall"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0001", "department": "Executive Board", "designation": "Chief Technology & Risk Officer", "contact_type": "Executive", "contact_email": "v.malhotra@acmefinance.com", "contact_phone": "+91-98200-11223", "contact_person": "Vikram Malhotra", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0002", "department": "Information Security", "designation": "Head of Information Security / vCISO", "contact_type": "Primary vCISO", "contact_email": "priya.sharma@acmefinance.com", "contact_phone": "+91-98200-33445", "contact_person": "Priya Sharma", "contact_priority": 1}, {"office_id": "Cust_00101_001", "contact_id": "Cust_00101_001_0003", "department": "IT Operations", "designation": "Security Operations Lead", "contact_type": "Escalation", "contact_email": "rohan.gupta@acmefinance.com", "contact_phone": "+91-98200-55667", "contact_person": "Rohan Gupta", "contact_priority": 2}], "industry": "Banking & Financial Services", "customer_id": "Cust_00101", "customer_name": "Acme Financial Services International Ltd.", "primary_domain": "acmefinance.com", "deployment_fqdn": "vciso.acmefinance.com"}, "initial_users": [{"user_id": "User_0001", "login_id": "priya.sharma", "office_id": "Cust_00101_001", "role_type": "vCISO", "user_name": "Priya Sharma", "department": "Information Security", "user_email": "priya.sharma@acmefinance.com", "designation": "vCISO", "user_mobile": "+91-98200-33445"}, {"user_id": "User_0002", "login_id": "vikram.malhotra", "office_id": "Cust_00101_001", "role_type": "Organisation Owner", "user_name": "Vikram Malhotra", "department": "Executive Board", "user_email": "v.malhotra@acmefinance.com", "designation": "CTO & Risk Officer", "user_mobile": "+91-98200-11223"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "mobile_access", "news_breach_watch", "incidents"], "licensing_limits": {"valid_to": "2027-03-31", "max_users": 25, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 20, "max_api_integrations": 10}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": true, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["Fintech leak", "Acme core banking"], "monitored_names": ["Acme Financial", "Acme Financial Services", "Acme International Bank"], "monitored_cities": ["Mumbai", "London", "Bengaluru"], "monitored_domains": ["acmefinance.com", "acmebank.co.in", "secure.acmefinance.com"]}, "selected_frameworks": [{"office_ids": ["Cust_00101_001", "Cust_00101_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00101_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v4 of Cust_00101 (build 7, full), image cybertrustworks/vciso-platform:cust_00101-v4

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for: Acme Financial Services International Ltd.
     Customer ID: Cust_00101
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed 577d04176afe9432...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00101\v4\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''incidents'', ''mobile_access'', ''news_breach_watch'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v4\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v4\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v4\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00101\v4\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   note: Integration ''Greenbone'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
   done in 0.7s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 0.9s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [builder 2/8] WORKDIR /app
   #6 CACHED
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #8 CACHED
   
   #9 [context instance] load from client
   #9 transferring instance: 606B 0.0s done
   #9 DONE 0.0s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.0s
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 ...
   
   #12 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #12 0.247 Building for Cust_00101 (instance 65cdf08b-115a-49cc-9f06-66ea535c1111), modules: alerting, compliance, incidents, mobile_access, news_breach_watch, vulnerabilities
   #12 DONE 0.3s
   
   #13 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #13 CACHED
   
   #14 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #14 CACHED
   
   #15 [builder 4/8] RUN npm ci
   #15 CACHED
   
   #16 [builder 5/8] COPY src ./src
   #16 CACHED
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 CACHED
   
   #18 [ui 2/6] WORKDIR /ui
   #18 CACHED
   
   #19 [ui 4/6] RUN npm ci
   #19 CACHED
   
   #20 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #20 CACHED
   
   #21 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #21 CACHED
   
   #22 [ui 6/6] RUN npm run build
   #22 CACHED
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 0.848 (1/1) Installing tini (0.19.0-r3)
   #11 0.859 Executing busybox-1.37.0-r31.trigger
   #11 0.864 OK: 10.9 MiB in 20 packages
   #11 DONE 1.0s
   
   #23 [production 3/8] WORKDIR /app
   #23 DONE 0.2s
   
   #24 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #24 DONE 0.3s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.1s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.1s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:129333251fa3b0a63053e7c5262d09f0b8e05fae2727a708004cacdc49d162e2 done
   #29 exporting config sha256:4e076a2be4e2c5fbc93cdf86a0966d1e7af20072872620d9f2304289691c5af0 done
   #29 exporting attestation manifest sha256:a10cf96ba8312bb4218ff79acff8b57d7a95bfd03c5bc18f929232095149ae18 0.0s done
   #29 exporting manifest list sha256:4e5fae6e63b9ffb685debbf4a6cb0fe98a976ba06a2bb1b913040d3b9e77b521 done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00101-v4 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v4
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00101-v4 0.2s done
   #29 DONE 0.5s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/n25f6h69misbklmwme77nd06h
   done in 4.0s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00101.tar.gz: 61.0 MB
   done in 4.4s

SUCCESS: cybertrustworks/vciso-platform:cust_00101-v4, instance 65cdf08b-115a-49cc-9f06-66ea535c1111
', NULL, 1, '2026-10-21 05:42:04.794238+00', '2026-10-21 05:42:04.806026+00', '2026-10-21 05:42:14.009523+00', NULL);
INSERT INTO public.ctw_build VALUES (12, 'Cust_00215', 1, 'full', NULL, 'success', '70d69e5b-8322-4a8f-97fc-d08d21a26bc1', 'ad714054188d849c774c7ee8cf4accf816b707457417ee403a7c719f82da4d84', 'cybertrustworks/vciso-platform:cust_00215-v1', 63951745, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00215\v1', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 3000, "financial_year": 2026, "customer_ref_po": "kaouc834672", "contract_end_date": "2027-11-15", "contract_start_date": "2026-10-21", "invoicing_frequency": "Q", "contract_period_months": 13}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": "http://atdshjdc.com", "pull_frequency_per_day": 1}, {"enabled": true, "tool_name": "Qualys", "target_endpoint": "https://haeyu.com", "pull_frequency_per_day": 4}]}, "organization": {"offices": [{"city": " Mumbai", "state": " Maharashtra", "country": " India", "pincode": "400051", "office_id": "Cust_00215_001", "office_type": "Primary", "office_address": " 3rd Floor, One BKC, Bandra Kurla Complex"}, {"city": " Navi Mumbai", "state": " Maharashtra", "country": "India", "pincode": "400710", "office_id": "Cust_00215_002", "office_type": "Data Center", "office_address": "Plot 7, TTC Industrial Area, Mahape"}], "category": "Financial Institution", "contacts": [{"office_id": "Cust_00215_001", "contact_id": "Cust_00215_001_0001", "department": "dferc dfcv", "designation": "saeuh ", "contact_type": "Executive", "contact_email": "anishku@gmail.com", "contact_phone": "98765432105", "contact_person": "anman", "contact_priority": 1}], "industry": "Banking & Financial Services", "customer_id": "Cust_00215", "customer_name": " Orion FinServ Pvt Ltd", "primary_domain": " orionfinserv.in", "deployment_fqdn": " "}, "initial_users": [{"user_id": "User_0001", "login_id": "akfdau@gmail", "office_id": "Cust_00215_001", "role_type": "vCISO", "user_name": "aofh nmcv", "department": "rtgf vghterh", "user_email": "anduha@gmail.com", "designation": "qfqcqfcf", "user_mobile": "9764523352"}, {"user_id": "User_0002", "login_id": "qfqfregrqqdc@gamil.com", "office_id": "Cust_00215_001", "role_type": "vCISO", "user_name": "qfre4dc ef", "department": " erfrecva", "user_email": "dvagahs@gamil.com", "designation": "werfgqv", "user_mobile": "efc erwf"}, {"user_id": "User_0003", "login_id": "fcuasgd@gmail.com", "office_id": "Cust_00215_001", "role_type": "Organisation Owner", "user_name": "aokhuwref", "department": "rqgft ghvb", "user_email": "asdfca@gamil.com", "designation": "aewf vce", "user_mobile": "987654323"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting"], "licensing_limits": {"valid_to": "2026-10-22", "max_users": 20, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 4, "max_api_integrations": 2}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": false, "password_expiry_days": 2, "session_timeout_minutes": 115}, "selected_frameworks": [{"office_ids": ["Cust_00215_001", "Cust_00215_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00215_002"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v1 of Cust_00215 (build 12, full), image cybertrustworks/vciso-platform:cust_00215-v1

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for:  Orion FinServ Pvt Ltd
     Customer ID: Cust_00215
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed ad714054188d849c...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00215\v1\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     note: Integration ''Qualys'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00215\v1\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00215\v1\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00215\v1\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00215\v1\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   note: Integration ''Qualys'' is not in the Tool-API-Map sheet; no API catalogue seeded for it
   done in 0.7s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 1.4s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:6a1c190e17215d844926b0677f4bf87273ff7d5e54db06d3b5b5863ab0b09a3d
   #5 resolve docker.io/library/node:24-alpine@sha256:6a1c190e17215d844926b0677f4bf87273ff7d5e54db06d3b5b5863ab0b09a3d 0.0s done
   #5 CACHED
   
   #6 [builder 3/8] COPY package*.json ./
   #6 CACHED
   
   #7 [builder 2/8] WORKDIR /app
   #7 CACHED
   
   #8 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #8 CACHED
   
   #9 [context instance] load from client
   #9 transferring instance: 520B 0.0s done
   #9 DONE 0.0s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.1s
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 ...
   
   #12 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #12 0.294 Building for Cust_00215 (instance 70d69e5b-8322-4a8f-97fc-d08d21a26bc1), modules: alerting, compliance, vulnerabilities
   #12 DONE 0.3s
   
   #13 [builder 4/8] RUN npm ci
   #13 CACHED
   
   #14 [builder 5/8] COPY src ./src
   #14 CACHED
   
   #15 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #15 CACHED
   
   #16 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #16 DONE 0.1s
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 0.452 
   #17 0.452 > vciso-platform-api@0.1.0 build
   #17 0.452 > node scripts/build.js
   #17 0.452 
   #17 0.516 WARNING: licensed module(s) not in this build: alerting. Available: compliance, vulnerabilities
   #17 0.516 Modules: compliance, vulnerabilities
   #17 1.965 Obfuscated 15 file(s)
   #17 DONE 2.0s
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 2.670 (1/1) Installing tini (0.19.0-r3)
   #11 2.690 Executing busybox-1.37.0-r31.trigger
   #11 2.698 OK: 10.9 MiB in 20 packages
   #11 DONE 2.7s
   
   #18 [production 3/8] WORKDIR /app
   #18 DONE 0.0s
   
   #19 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #19 ...
   
   #20 [ui 4/6] RUN npm ci
   #20 CACHED
   
   #21 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #21 CACHED
   
   #22 [ui 2/6] WORKDIR /ui
   #22 CACHED
   
   #23 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #23 CACHED
   
   #24 [ui 6/6] RUN npm run build
   #24 CACHED
   
   #19 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #19 DONE 0.4s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.1s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.0s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:cf013bafc9119326016086a1e7c5f84b5888933b295f91f068b8af8f9d32a1e7 0.0s done
   #29 exporting config sha256:189e1fa425b2707ffaccb8b19f90b55841de580b0142f1c20425f4c3b6ac71db done
   #29 exporting attestation manifest sha256:2246de0b9c077c7dd8d0b0ff17610b1077bf6686cd984396d7c61eeac7ad6901 0.0s done
   #29 exporting manifest list sha256:c6a0ade82da9c6a68f673cd4dc35ccbf00c0b050fa236a055b0015cd0f4b2c4d done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00215-v1 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00215-v1
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00215-v1 0.3s done
   #29 DONE 0.6s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/swfvzcywkpx4ewzjkrgwx843k
   done in 6.0s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00215.tar.gz: 61.0 MB
   done in 2.7s

SUCCESS: cybertrustworks/vciso-platform:cust_00215-v1, instance 70d69e5b-8322-4a8f-97fc-d08d21a26bc1
', NULL, 7, '2026-10-21 16:47:26.228789+00', '2026-10-21 16:47:26.244986+00', '2026-10-21 16:47:35.857717+00', NULL);
INSERT INTO public.ctw_build VALUES (10, 'Cust_00206', 1, 'full', NULL, 'success', '3ec5ae5e-3b8f-44df-8257-5aaead4fd173', 'ed6817848199885b76ffb238f86eed47feded3b46de5e5ecfb29cb45abc12b9b', 'cybertrustworks/vciso-platform:cust_00206-v1', 63914474, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00206\v1', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 900000, "financial_year": 2026, "customer_ref_po": " PO-GLX-2026-01", "contract_end_date": "2027-10-20", "contract_start_date": "2026-10-21", "invoicing_frequency": "M", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": " https://cloud.tenable.com,", "pull_frequency_per_day": 2}]}, "organization": {"offices": [{"city": "Bengaluru", "state": "Karnataka", "country": "India", "pincode": " 560001", "office_id": "Cust_00206_001", "office_type": "Primary", "office_address": "│ 4th Floor, Prestige Tower, MG Road"}, {"city": "Pune", "state": "Maharashtra", "country": "India", "pincode": "411057", "office_id": "Cust_00206_002", "office_type": "Secondary", "office_address": "Plot 22, Hinjewadi Phase"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00206_001", "contact_id": "Cust_00206_001_0001", "department": "", "designation": " Chief Executive Officer", "contact_type": "Executive", "contact_email": "rahul.mehta@globexhealth.in", "contact_phone": "+91-98450-11111", "contact_person": " Rahul", "contact_priority": 1}, {"office_id": "Cust_00206_001", "contact_id": "Cust_00206_001_0002", "department": "", "designation": "Head of Information Security", "contact_type": "Executive", "contact_email": "anish@globexhealth.in", "contact_phone": "+91-98450-22222", "contact_person": "Anish", "contact_priority": 1}, {"office_id": "Cust_00206_001", "contact_id": "Cust_00206_001_0003", "department": "", "designation": "IT Operations Lead", "contact_type": "Executive", "contact_email": "sneha.k@globexhealth.in", "contact_phone": "+91-98450-33333", "contact_person": "Sneha  Kulkarni", "contact_priority": 1}], "industry": " Healthcare", "customer_id": "Cust_00206", "customer_name": "Globex Health Pvt Ltd", "primary_domain": " globexhealth.in", "deployment_fqdn": "vciso.globexhealth.in"}, "initial_users": [{"user_id": "User_0001", "login_id": "anish.globex", "office_id": "Cust_00206_001", "role_type": "vCISO", "user_name": " Anish ", "department": "", "user_email": "anish@globexhealth.in", "designation": "", "user_mobile": ""}, {"user_id": "User_0002", "login_id": "rahul.mehta", "office_id": "Cust_00206_001", "role_type": "Organisation Owner", "user_name": "Rahul Mehta", "department": "", "user_email": "rahul.mehta@globexhealth.in", "designation": "", "user_mobile": ""}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "news_breach_watch"], "licensing_limits": {"valid_to": "2027-10-20", "max_users": 20, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 10, "max_api_integrations": 5}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": false, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["patient data leak"], "monitored_names": ["Globex Health"], "monitored_cities": ["Bengaluru"], "monitored_domains": ["globexhealth.in"]}, "selected_frameworks": [{"office_ids": ["Cust_00206_001", "Cust_00206_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00206_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v1 of Cust_00206 (build 10, full), image cybertrustworks/vciso-platform:cust_00206-v1

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for: Globex Health Pvt Ltd
     Customer ID: Cust_00206
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed ed6817848199885b...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00206\v1\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''news_breach_watch'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00206\v1\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00206\v1\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00206\v1\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00206\v1\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   done in 1.0s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 1.6s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f
   #5 resolve docker.io/library/node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f 0.0s done
   #5 CACHED
   
   #6 [builder 2/8] WORKDIR /app
   #6 CACHED
   
   #7 [builder 3/8] COPY package*.json ./
   #7 CACHED
   
   #8 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #8 CACHED
   
   #9 [context instance] load from client
   #9 transferring instance: 545B 0.0s done
   #9 DONE 0.0s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.0s
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 ...
   
   #12 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #12 0.571 Building for Cust_00206 (instance 3ec5ae5e-3b8f-44df-8257-5aaead4fd173), modules: alerting, compliance, news_breach_watch, vulnerabilities
   #12 DONE 0.6s
   
   #13 [builder 5/8] COPY src ./src
   #13 CACHED
   
   #14 [builder 4/8] RUN npm ci
   #14 CACHED
   
   #15 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #15 CACHED
   
   #16 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #16 DONE 0.0s
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 0.467 
   #17 0.467 > vciso-platform-api@0.1.0 build
   #17 0.467 > node scripts/build.js
   #17 0.467 
   #17 0.523 WARNING: licensed module(s) not in this build: alerting, news_breach_watch. Available: compliance, vulnerabilities
   #17 0.524 Modules: compliance, vulnerabilities
   #17 ...
   
   #11 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #11 1.255 (1/1) Installing tini (0.19.0-r3)
   #11 1.282 Executing busybox-1.37.0-r31.trigger
   #11 1.299 OK: 10.9 MiB in 20 packages
   #11 DONE 1.4s
   
   #18 [production 3/8] WORKDIR /app
   #18 DONE 0.0s
   
   #19 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #19 DONE 0.5s
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 ...
   
   #20 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #20 CACHED
   
   #21 [ui 2/6] WORKDIR /ui
   #21 CACHED
   
   #22 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #22 CACHED
   
   #23 [ui 4/6] RUN npm ci
   #23 CACHED
   
   #24 [ui 6/6] RUN npm run build
   #24 CACHED
   
   #17 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #17 0.976 Obfuscated 15 file(s)
   #17 DONE 1.0s
   
   #25 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #25 DONE 0.1s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.1s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.0s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:727a2b56fd2eb1458e244d6f48239b09d6e494f715694797ce0f8e76e9aaf1e8 0.0s done
   #29 exporting config sha256:67059e4cbbbb0e1e6de85d837db50791e6616d09e6f3b20d4269c5f7f9415116 done
   #29 exporting attestation manifest sha256:a062e3354ca2cf95c6bd5c76d6c2f2eb734ddd4f6783a6f3bfcecf746496aa86 0.0s done
   #29 exporting manifest list sha256:fa1b924fbb6aa0d2fe692eab963f8864cf182d162bd86645bb49596209e8add3 done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00206-v1 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00206-v1
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00206-v1 0.2s done
   #29 DONE 0.5s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/ztrkupomvsf1efqq6tvn9ciw3
   done in 5.8s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00206.tar.gz: 61.0 MB
   done in 2.6s

SUCCESS: cybertrustworks/vciso-platform:cust_00206-v1, instance 3ec5ae5e-3b8f-44df-8257-5aaead4fd173
', NULL, 7, '2026-10-21 11:56:07.686798+00', '2026-10-21 11:56:07.704609+00', '2026-10-21 11:56:16.539688+00', NULL);
INSERT INTO public.ctw_build VALUES (11, 'Cust_00210', 1, 'full', NULL, 'success', 'e7b3b087-7c94-4761-b611-545723dd49bb', 'e6f8aac6df28579fa9d523b66c6f748a36a71cf37447cf175abbd2caf4e5da8b', 'cybertrustworks/vciso-platform:cust_00210-v1', 63951140, 'C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00210\v1', '{"contract": {"currency": "INR", "contract_id": "Contract_001", "contract_type": "Original", "contract_value": 750000, "financial_year": 2026, "customer_ref_po": "PO-NIM-2026-001", "contract_end_date": "2027-10-21", "contract_start_date": "2026-10-21", "invoicing_frequency": "Q", "contract_period_months": 12}, "integrations": {"tools": [{"enabled": true, "tool_name": "Tenable", "target_endpoint": " https://cloud.tenable.com", "pull_frequency_per_day": 2}]}, "organization": {"offices": [{"city": "Hyderabad", "state": "Telangana", "country": "India", "pincode": "500081", "office_id": "Cust_00210_001", "office_type": "Primary", "office_address": " 5th Floor, Cyber Towers, Hitech City"}, {"city": "Mumbai", "state": "Maharashtra", "country": "India", "pincode": "400093", "office_id": "Cust_00210_002", "office_type": "Secondary", "office_address": "Unit 12, MIDC Andheri East"}], "category": "Enterprise", "contacts": [{"office_id": "Cust_00210_001", "contact_id": "Cust_00210_001_0001", "department": "Management", "designation": "Managing Director", "contact_type": "Executive", "contact_email": "vikas.reddy@nimbuslogistics.in", "contact_phone": "9848010001", "contact_person": "Vikas Reddy", "contact_priority": 1}, {"office_id": "Cust_00210_002", "contact_id": "Cust_00210_001_0002", "department": " IT", "designation": "IT Operations Head", "contact_type": "Escalation", "contact_email": "neha.joshi@nimbuslogistics.in", "contact_phone": "9820010002", "contact_person": " Neha Joshi", "contact_priority": 2}], "industry": "Logistics", "customer_id": "Cust_00210", "customer_name": "Nimbus Logistics Pvt Ltd", "primary_domain": "nimbuslogistics.in", "deployment_fqdn": " vciso.nimbuslogistics.in"}, "initial_users": [{"user_id": "User_0001", "login_id": "arjun.mehta", "office_id": "Cust_00210_001", "role_type": "vCISO", "user_name": "Arjun Mehta", "department": "Information Security", "user_email": "arjun.mehta@nimbuslogistics.in", "designation": " Head of Information Security", "user_mobile": "9848020001"}, {"user_id": "User_0002", "login_id": "vikas.reddy", "office_id": "Cust_00210_001", "role_type": "Organisation Owner", "user_name": " Vikas Reddy", "department": "Management", "user_email": "vikas.reddy@nimbuslogistics.in", "designation": "Managing Director", "user_mobile": "9848010001"}], "enabled_modules": ["compliance", "vulnerabilities", "alerting", "news_breach_watch"], "licensing_limits": {"valid_to": "2027-10-20", "max_users": 20, "max_vcisos": 2, "max_frameworks": 2, "max_org_owners": 1, "max_control_owners": 10, "max_api_integrations": 5}, "security_policies": {"sso_type": "LOCAL", "mfa_enforced": false, "password_expiry_days": 90, "session_timeout_minutes": 15}, "news_watch_profile": {"custom_keywords": ["shipment data leak"], "monitored_names": ["Nimbus Logistics"], "monitored_cities": ["Hyderabad"], "monitored_domains": ["nimbuslogistics.in"]}, "selected_frameworks": [{"office_ids": ["Cust_00210_001", "Cust_00210_002"], "framework_id": 102, "review_frequency_months": 12}, {"office_ids": ["Cust_00210_001"], "framework_id": 103, "review_frequency_months": 6}]}', 'Build v1 of Cust_00210 (build 11, full), image cybertrustworks/vciso-platform:cust_00210-v1

== 1/4 Client spec from the CTW database
   done in 0.0s

== 2/4 Bundle: validate, seal, schema, compose
   =======================================================
     CyberTrustWorks Release Builder for: Nimbus Logistics Pvt Ltd
     Customer ID: Cust_00210
   =======================================================
   [1/4] Validating and sealing the intake specification...
     OK  Specification valid; licence sealed e6f8aac6df28579f...
   [2/4] Generating tailored database schema & filtered seed...
   [SUCCESS] ctw-admin\builds\Cust_00210\v1\bundle\001_client_init.sql: 25 workbook tables + modules [''alerting'', ''compliance'', ''news_breach_watch'', ''vulnerabilities''], 196 licensed controls, frameworks [102, 103]
     note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
     note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
     OK  Database schema created: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00210\v1\bundle\001_client_init.sql
   [3/4] Generating client docker-compose.yml...
     OK  Client compose manifest written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00210\v1\bundle\docker-compose.yml
   [4/4] Writing client deployment guide...
     OK  Client deployment instructions written: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00210\v1\bundle\README.md
   [DONE] Client bundle generated at: C:\Anish\company\Ayush\test2\vciso-platform-share-2026-10-19\vciso-platform\ctw-admin\builds\Cust_00210\v1\bundle
     - 001_client_init.sql
     - README.md
     - client_spec.json
     - docker-compose.yml
     - instance.json
   note: UI-Report-Dashboard-List: UI_RD_0002 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0003 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0004 appears more than once; first row kept
   note: UI-Report-Dashboard-List: UI_RD_0005 appears more than once; first row kept
   done in 0.6s

== 3/4 Docker image
   #0 building with "desktop-linux" instance using docker driver
   
   #1 [internal] load build definition from Dockerfile
   #1 transferring dockerfile: 4.64kB 0.0s done
   #1 DONE 0.0s
   
   #2 [context instance] load .dockerignore
   #2 transferring instance: 2B done
   #2 DONE 0.0s
   
   #3 [internal] load metadata for docker.io/library/node:24-alpine
   #3 DONE 2.3s
   
   #4 [internal] load build context
   #4 transferring context: 10.97kB 0.0s done
   #4 DONE 0.0s
   
   #5 [context instance] load from client
   #5 transferring instance: 548B 0.0s done
   #5 DONE 0.0s
   
   #6 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:6a1c190e17215d844926b0677f4bf87273ff7d5e54db06d3b5b5863ab0b09a3d
   #6 resolve docker.io/library/node:24-alpine@sha256:6a1c190e17215d844926b0677f4bf87273ff7d5e54db06d3b5b5863ab0b09a3d 0.0s done
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 0B / 57.37MB 0.2s
   #6 sha256:ffd4ace32a62e2f0eb47d6276ea3d131baaf4f1d27ad6b951fb057b5e50665fc 0B / 1.26MB 0.2s
   #6 sha256:28186c8c3a4726e50fbff6f9b8ecb06a83c72aa645f5253b6fc1fa14bf65bc44 0B / 442B 0.2s
   #6 sha256:28186c8c3a4726e50fbff6f9b8ecb06a83c72aa645f5253b6fc1fa14bf65bc44 442B / 442B 0.5s done
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 3.15MB / 57.37MB 0.9s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 6.29MB / 57.37MB 1.2s
   #6 sha256:ffd4ace32a62e2f0eb47d6276ea3d131baaf4f1d27ad6b951fb057b5e50665fc 1.26MB / 1.26MB 1.3s done
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 9.44MB / 57.37MB 1.7s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 12.58MB / 57.37MB 2.3s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 15.73MB / 57.37MB 2.6s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 18.87MB / 57.37MB 3.0s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 23.07MB / 57.37MB 3.5s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 26.21MB / 57.37MB 3.9s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 29.36MB / 57.37MB 4.2s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 33.55MB / 57.37MB 4.7s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 37.75MB / 57.37MB 5.1s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 40.89MB / 57.37MB 5.4s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 45.09MB / 57.37MB 5.9s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 48.23MB / 57.37MB 6.2s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 51.38MB / 57.37MB 7.4s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 54.53MB / 57.37MB 8.3s
   #6 sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 57.37MB / 57.37MB 8.9s done
   #6 extracting sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a
   #6 extracting sha256:1d93122a5ea1bd309bdff36d7f7dbf3706228748bf200163b5a5f0dbad23573a 1.1s done
   #6 DONE 10.0s
   
   #6 [ui 1/6] FROM docker.io/library/node:24-alpine@sha256:6a1c190e17215d844926b0677f4bf87273ff7d5e54db06d3b5b5863ab0b09a3d
   #6 extracting sha256:ffd4ace32a62e2f0eb47d6276ea3d131baaf4f1d27ad6b951fb057b5e50665fc 0.0s done
   #6 extracting sha256:28186c8c3a4726e50fbff6f9b8ecb06a83c72aa645f5253b6fc1fa14bf65bc44 0.0s done
   #6 DONE 10.1s
   
   #7 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #7 ...
   
   #8 [builder 2/8] WORKDIR /app
   #8 DONE 0.9s
   
   #9 [ui 2/6] WORKDIR /ui
   #9 DONE 0.9s
   
   #10 [identity 2/3] COPY --from=instance instance.json /instance/instance.json
   #10 DONE 0.9s
   
   #11 [ui 3/6] COPY vciso-platform/vciso-app/package*.json ./
   #11 DONE 0.0s
   
   #12 [builder 3/8] COPY package*.json ./
   #12 DONE 0.1s
   
   #13 [ui 4/6] RUN npm ci
   #13 ...
   
   #14 [identity 3/3] RUN node -e "   const i = require(''/instance/instance.json'');   for (const k of [''instance_id'', ''customer_id'', ''license_id'', ''license_seal'', ''schema_version'', ''licensed_modules''])     if (!i[k]) { console.error(''instance.json has no '' + k); process.exit(1); }   require(''fs'').writeFileSync(''/instance/modules'', i.licensed_modules.join('',''));   console.log(''Building for '' + i.customer_id + '' (instance '' + i.instance_id + ''), modules: '' + i.licensed_modules.join('', ''));"
   #14 0.465 Building for Cust_00210 (instance e7b3b087-7c94-4761-b611-545723dd49bb), modules: alerting, compliance, news_breach_watch, vulnerabilities
   #14 DONE 0.5s
   
   #15 [builder 4/8] RUN npm ci
   #15 ...
   
   #16 [production 3/8] WORKDIR /app
   #16 DONE -0.4s
   
   #7 [production 2/8] RUN apk add --no-cache tini && mkdir -p /data/evidence /app/instance && chown -R node:node /data
   #7 2.188 (1/1) Installing tini (0.19.0-r3)
   #7 2.210 Executing busybox-1.37.0-r31.trigger
   #7 2.223 OK: 10.9 MiB in 20 packages
   #7 DONE 2.3s
   
   #17 [prod-deps 4/4] RUN npm ci --omit=dev && npm cache clean --force
   #17 2.477 
   #17 2.477 added 93 packages, and audited 94 packages in 2s
   #17 2.477 
   #17 2.477 18 packages are looking for funding
   #17 2.477   run `npm fund` for details
   #17 2.478 
   #17 2.478 found 0 vulnerabilities
   #17 2.483 npm notice
   #17 2.483 npm notice New major version of npm available! 11.19.1 -> 12.2.0
   #17 2.483 npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
   #17 2.483 npm notice To update run: npm install -g npm@12.2.0
   #17 2.483 npm notice
   #17 2.665 npm warn using --force Recommended protections disabled.
   #17 DONE 3.0s
   
   #13 [ui 4/6] RUN npm ci
   #13 ...
   
   #18 [production 4/8] COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
   #18 DONE 0.2s
   
   #15 [builder 4/8] RUN npm ci
   #15 4.322 npm warn deprecated eslint@9.39.5: This version is no longer supported. Please see https://eslint.org/version-support for other options.
   #15 4.938 
   #15 4.938 added 263 packages, and audited 264 packages in 4s
   #15 4.938 
   #15 4.938 72 packages are looking for funding
   #15 4.938   run `npm fund` for details
   #15 4.940 
   #15 4.940 found 0 vulnerabilities
   #15 4.943 npm notice
   #15 4.943 npm notice New major version of npm available! 11.19.1 -> 12.2.0
   #15 4.943 npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
   #15 4.943 npm notice To update run: npm install -g npm@12.2.0
   #15 4.943 npm notice
   #15 DONE 5.1s
   
   #13 [ui 4/6] RUN npm ci
   #13 5.132 
   #13 5.132 added 89 packages, and audited 90 packages in 5s
   #13 5.132 
   #13 5.132 8 packages are looking for funding
   #13 5.132   run `npm fund` for details
   #13 5.153 
   #13 5.153 10 vulnerabilities (5 moderate, 5 high)
   #13 5.153 
   #13 5.153 To address issues that do not require attention, run:
   #13 5.153   npm audit fix
   #13 5.153 
   #13 5.153 To address all issues (including breaking changes), run:
   #13 5.153   npm audit fix --force
   #13 5.153 
   #13 5.153 Run `npm audit` for details.
   #13 5.154 npm warn install-scripts 2 packages have install scripts not yet covered by allowScripts:
   #13 5.154 npm warn install-scripts   core-js@3.49.0 (postinstall: node -e "try{require(''./postinstall'')}catch(e){}")
   #13 5.154 npm warn install-scripts   esbuild@0.21.5 (postinstall: node install.js)
   #13 5.154 npm warn install-scripts
   #13 5.154 npm warn install-scripts Run `npm install-scripts ls` to review, or `npm install-scripts approve <pkg>` to allow.
   #13 5.155 npm notice
   #13 5.155 npm notice New major version of npm available! 11.19.1 -> 12.2.0
   #13 5.155 npm notice Changelog: https://github.com/npm/cli/releases/tag/v12.2.0
   #13 5.155 npm notice To update run: npm install -g npm@12.2.0
   #13 5.155 npm notice
   #13 DONE 5.2s
   
   #19 [builder 5/8] COPY src ./src
   #19 DONE 0.1s
   
   #20 [ui 5/6] COPY vciso-platform/vciso-app/ ./
   #20 DONE 0.1s
   
   #21 [builder 6/8] COPY scripts/build.js ./scripts/build.js
   #21 DONE 0.0s
   
   #22 [builder 7/8] COPY --from=identity /instance/modules /tmp/modules
   #22 DONE 0.0s
   
   #23 [builder 8/8] RUN ENABLED_MODULES="$(cat /tmp/modules)" OBFUSCATE="true" npm run build
   #23 0.361 
   #23 0.361 > vciso-platform-api@0.1.0 build
   #23 0.361 > node scripts/build.js
   #23 0.361 
   #23 0.397 WARNING: licensed module(s) not in this build: alerting, news_breach_watch. Available: compliance, vulnerabilities
   #23 0.398 Modules: compliance, vulnerabilities
   #23 1.577 Obfuscated 15 file(s)
   #23 DONE 1.6s
   
   #24 [production 5/8] COPY --from=builder   --chown=node:node /app/dist ./dist
   #24 DONE 0.0s
   
   #25 [ui 6/6] RUN npm run build
   #25 0.376 
   #25 0.376 > vciso-frontend@1.0.0 build
   #25 0.376 > vite build
   #25 0.376 
   #25 0.581 vite v5.4.21 building for production...
   #25 0.634 transforming...
   #25 3.775 ✓ 480 modules transformed.
   #25 4.030 rendering chunks...
   #25 4.446 computing gzip size...
   #25 4.507 dist/index.html                        2.50 kB │ gzip:   1.03 kB
   #25 4.507 dist/assets/index-CEF1M2kZ.css        19.30 kB │ gzip:   3.97 kB
   #25 4.507 dist/assets/index-BBlvRDmi.css        20.94 kB │ gzip:   4.23 kB
   #25 4.507 dist/assets/index-DPXX4RIV.css        25.56 kB │ gzip:   4.97 kB
   #25 4.507 dist/assets/purify.es-CPrKKeqe.js     28.07 kB │ gzip:  10.66 kB
   #25 4.507 dist/assets/index.es-CLy1P0D6.js     150.69 kB │ gzip:  51.55 kB
   #25 4.507 dist/assets/index-CNiAJwNj.js      2,505.81 kB │ gzip: 614.67 kB
   #25 4.507 
   #25 4.507 (!) Some chunks are larger than 500 kB after minification. Consider:
   #25 4.507 - Using dynamic import() to code-split the application
   #25 4.507 - Use build.rollupOptions.output.manualChunks to improve chunking: https://rollupjs.org/configuration-options/#output-manualchunks
   #25 4.507 - Adjust chunk size limit for this warning via build.chunkSizeWarningLimit.
   #25 4.508 ✓ built in 3.90s
   #25 DONE 4.6s
   
   #26 [production 6/8] COPY --from=ui        --chown=node:node /ui/dist ./ui
   #26 DONE 0.0s
   
   #27 [production 7/8] COPY --from=identity --chmod=444 /instance/instance.json ./instance/instance.json
   #27 DONE 0.0s
   
   #28 [production 8/8] COPY --chown=node:node package.json ./
   #28 DONE 0.1s
   
   #29 exporting to image
   #29 exporting layers
   #29 exporting layers 0.2s done
   #29 exporting manifest sha256:abaefbec8054eb7040299a45f93523b4e500d78d66189a7d4a2b6858097dd5d3 0.0s done
   #29 exporting config sha256:8a104b52126b306d47e6f9ef4cca077cae7ecbbd76a33e7d9735b75cd9c33e49 done
   #29 exporting attestation manifest sha256:64af7a3162e831239a6b1dc3b5b3c260bf20c7a4443bee2c9afc1bc9fe32b03b 0.0s done
   #29 exporting manifest list sha256:86503f955de2c95885ea18dd15d1cfc907f6a2b389109623ef0284357b0a3cd7 done
   #29 naming to docker.io/cybertrustworks/vciso-platform:cust_00210-v1 done
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00210-v1
   #29 unpacking to docker.io/cybertrustworks/vciso-platform:cust_00210-v1 0.2s done
   #29 DONE 0.5s
   
   View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/rx7006tfktxafgna3fuz1owxm
   done in 24.8s

== 4/4 Image file (docker save | gzip)
   vciso-platform-cust_00210.tar.gz: 61.0 MB
   done in 2.6s

SUCCESS: cybertrustworks/vciso-platform:cust_00210-v1, instance e7b3b087-7c94-4761-b611-545723dd49bb
', NULL, 7, '2026-10-21 14:41:06.082523+00', '2026-10-21 14:41:06.099617+00', '2026-10-21 14:41:34.059862+00', NULL);


--
-- Data for Name: ctw_client; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client VALUES ('Cust_00202', 'Globex Health Pvt Ltd', 'Enterprise', ' Healthcare', ' globexhealth.in', 'vciso.globexhealth.in', 'draft', 7, '2026-10-21 10:50:53.561257+00', '2026-10-21 11:20:04.430313+00');
INSERT INTO public.ctw_client VALUES ('Cust_00206', 'Globex Health Pvt Ltd', 'Enterprise', ' Healthcare', ' globexhealth.in', 'vciso.globexhealth.in', 'generated', 7, '2026-10-21 11:15:56.776699+00', '2026-10-21 11:56:16.542139+00');
INSERT INTO public.ctw_client VALUES ('Cust_00210', 'Nimbus Logistics Pvt Ltd', 'Enterprise', 'Logistics', 'nimbuslogistics.in', ' vciso.nimbuslogistics.in', 'generated', 7, '2026-10-21 14:27:26.234337+00', '2026-10-21 14:41:34.062339+00');
INSERT INTO public.ctw_client VALUES ('Cust_00215', ' Orion FinServ Pvt Ltd', 'Financial Institution', 'Banking & Financial Services', ' orionfinserv.in', ' ', 'generated', 7, '2026-10-21 16:16:44.561983+00', '2026-10-21 16:47:35.860009+00');
INSERT INTO public.ctw_client VALUES ('Cust_00101', 'Acme Financial Services International Ltd.', 'Enterprise', 'Banking & Financial Services', 'acmefinance.com', 'vciso.acmefinance.com', 'generated', 1, '2026-10-21 04:54:09.922004+00', '2026-10-21 05:41:29.260583+00');


--
-- Data for Name: ctw_client_contact; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_contact VALUES ('Cust_00101_001_0001', 'Cust_00101', 'Cust_00101_001', 'Executive', 1, 'Vikram Malhotra', 'Chief Technology & Risk Officer', 'Executive Board', 'v.malhotra@acmefinance.com', '+91-98200-11223');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00101_001_0002', 'Cust_00101', 'Cust_00101_001', 'Primary vCISO', 1, 'Priya Sharma', 'Head of Information Security / vCISO', 'Information Security', 'priya.sharma@acmefinance.com', '+91-98200-33445');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00101_001_0003', 'Cust_00101', 'Cust_00101_001', 'Escalation', 2, 'Rohan Gupta', 'Security Operations Lead', 'IT Operations', 'rohan.gupta@acmefinance.com', '+91-98200-55667');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00206_001_0001', 'Cust_00206', 'Cust_00206_001', 'Executive', 1, ' Rahul', ' Chief Executive Officer', '', 'rahul.mehta@globexhealth.in', '+91-98450-11111');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00206_001_0002', 'Cust_00206', 'Cust_00206_001', 'Executive', 1, 'Anish', 'Head of Information Security', '', 'anish@globexhealth.in', '+91-98450-22222');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00206_001_0003', 'Cust_00206', 'Cust_00206_001', 'Executive', 1, 'Sneha  Kulkarni', 'IT Operations Lead', '', 'sneha.k@globexhealth.in', '+91-98450-33333');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00210_001_0001', 'Cust_00210', 'Cust_00210_001', 'Executive', 1, 'Vikas Reddy', 'Managing Director', 'Management', 'vikas.reddy@nimbuslogistics.in', '9848010001');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00210_001_0002', 'Cust_00210', 'Cust_00210_002', 'Escalation', 2, ' Neha Joshi', 'IT Operations Head', ' IT', 'neha.joshi@nimbuslogistics.in', '9820010002');
INSERT INTO public.ctw_client_contact VALUES ('Cust_00215_001_0001', 'Cust_00215', 'Cust_00215_001', 'Executive', 1, 'anman', 'saeuh ', 'dferc dfcv', 'anishku@gmail.com', '98765432105');


--
-- Data for Name: ctw_client_initial_user; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00101', 'User_0001', 'priya.sharma', 'Priya Sharma', 'priya.sharma@acmefinance.com', '+91-98200-33445', 'vCISO', 'Information Security', 'vCISO', 'Cust_00101_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00101', 'User_0002', 'vikram.malhotra', 'Vikram Malhotra', 'v.malhotra@acmefinance.com', '+91-98200-11223', 'CTO & Risk Officer', 'Executive Board', 'Organisation Owner', 'Cust_00101_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00206', 'User_0001', 'anish.globex', ' Anish ', 'anish@globexhealth.in', '', '', '', 'vCISO', 'Cust_00206_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00206', 'User_0002', 'rahul.mehta', 'Rahul Mehta', 'rahul.mehta@globexhealth.in', '', '', '', 'Organisation Owner', 'Cust_00206_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00210', 'User_0001', 'arjun.mehta', 'Arjun Mehta', 'arjun.mehta@nimbuslogistics.in', '9848020001', ' Head of Information Security', 'Information Security', 'vCISO', 'Cust_00210_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00210', 'User_0002', 'vikas.reddy', ' Vikas Reddy', 'vikas.reddy@nimbuslogistics.in', '9848010001', 'Managing Director', 'Management', 'Organisation Owner', 'Cust_00210_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00215', 'User_0001', 'akfdau@gmail', 'aofh nmcv', 'anduha@gmail.com', '9764523352', 'qfqcqfcf', 'rtgf vghterh', 'vCISO', 'Cust_00215_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00215', 'User_0002', 'qfqfregrqqdc@gamil.com', 'qfre4dc ef', 'dvagahs@gamil.com', 'efc erwf', 'werfgqv', ' erfrecva', 'vCISO', 'Cust_00215_001');
INSERT INTO public.ctw_client_initial_user VALUES ('Cust_00215', 'User_0003', 'fcuasgd@gmail.com', 'aokhuwref', 'asdfca@gamil.com', '987654323', 'aewf vce', 'rqgft ghvb', 'Organisation Owner', 'Cust_00215_001');


--
-- Data for Name: ctw_client_news_watch; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_news_watch VALUES ('Cust_00101', '{"Acme Financial","Acme Financial Services","Acme International Bank"}', '{acmefinance.com,acmebank.co.in,secure.acmefinance.com}', '{Mumbai,London,Bengaluru}', '{"Fintech leak","Acme core banking"}');
INSERT INTO public.ctw_client_news_watch VALUES ('Cust_00206', '{"Globex Health"}', '{globexhealth.in}', '{Bengaluru}', '{"patient data leak"}');
INSERT INTO public.ctw_client_news_watch VALUES ('Cust_00210', '{"Nimbus Logistics"}', '{nimbuslogistics.in}', '{Hyderabad}', '{"shipment data leak"}');


--
-- Data for Name: ctw_client_office; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_office VALUES ('Cust_00101_001', 'Cust_00101', 'Primary', 'Tower 4, Bandra Kurla Complex', 'Mumbai', 'Maharashtra', 'India', '400051');
INSERT INTO public.ctw_client_office VALUES ('Cust_00101_002', 'Cust_00101', 'Secondary', '77 London Wall', 'London', 'Greater London', 'United Kingdom', 'EC2M 5TN');
INSERT INTO public.ctw_client_office VALUES ('Cust_00206_001', 'Cust_00206', 'Primary', '│ 4th Floor, Prestige Tower, MG Road', 'Bengaluru', 'Karnataka', 'India', ' 560001');
INSERT INTO public.ctw_client_office VALUES ('Cust_00206_002', 'Cust_00206', 'Secondary', 'Plot 22, Hinjewadi Phase', 'Pune', 'Maharashtra', 'India', '411057');
INSERT INTO public.ctw_client_office VALUES ('Cust_00210_001', 'Cust_00210', 'Primary', ' 5th Floor, Cyber Towers, Hitech City', 'Hyderabad', 'Telangana', 'India', '500081');
INSERT INTO public.ctw_client_office VALUES ('Cust_00210_002', 'Cust_00210', 'Secondary', 'Unit 12, MIDC Andheri East', 'Mumbai', 'Maharashtra', 'India', '400093');
INSERT INTO public.ctw_client_office VALUES ('Cust_00215_001', 'Cust_00215', 'Primary', ' 3rd Floor, One BKC, Bandra Kurla Complex', ' Mumbai', ' Maharashtra', ' India', '400051');
INSERT INTO public.ctw_client_office VALUES ('Cust_00215_002', 'Cust_00215', 'Data Center', 'Plot 7, TTC Industrial Area, Mahape', ' Navi Mumbai', ' Maharashtra', 'India', '400710');


--
-- Data for Name: ctw_client_security_policy; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_security_policy VALUES ('Cust_00101', 'LOCAL', NULL, true, 90, 15);
INSERT INTO public.ctw_client_security_policy VALUES ('Cust_00202', 'LOCAL', NULL, true, 90, 15);
INSERT INTO public.ctw_client_security_policy VALUES ('Cust_00206', 'LOCAL', NULL, false, 90, 15);
INSERT INTO public.ctw_client_security_policy VALUES ('Cust_00210', 'LOCAL', NULL, false, 90, 15);
INSERT INTO public.ctw_client_security_policy VALUES ('Cust_00215', 'LOCAL', NULL, false, 2, 115);


--
-- Data for Name: ctw_client_tool; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_client_tool VALUES ('Cust_00101', 'Tenable', true, 'https://cloud.tenable.com', 2, 0);
INSERT INTO public.ctw_client_tool VALUES ('Cust_00101', 'Greenbone', true, 'https://scanner.internal.acmefinance.com:9390', 1, 1);
INSERT INTO public.ctw_client_tool VALUES ('Cust_00206', 'Tenable', true, ' https://cloud.tenable.com,', 2, 0);
INSERT INTO public.ctw_client_tool VALUES ('Cust_00210', 'Tenable', true, ' https://cloud.tenable.com', 2, 0);
INSERT INTO public.ctw_client_tool VALUES ('Cust_00215', 'Tenable', true, 'http://atdshjdc.com', 1, 0);
INSERT INTO public.ctw_client_tool VALUES ('Cust_00215', 'Qualys', true, 'https://haeyu.com', 4, 1);


--
-- Data for Name: ctw_contract; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_contract VALUES ('Cust_00101', 'Contract_001', 'PO_ACME_2026_09', 'Original', 2026, 12, '2026-04-01', '2027-03-31', 1200000.00, 'INR', 'M', true);
INSERT INTO public.ctw_contract VALUES ('Cust_00202', 'Contract_001', '', 'Original', 2026, 12, '2026-10-21', '2027-10-20', 0.00, 'INR', 'M', true);
INSERT INTO public.ctw_contract VALUES ('Cust_00206', 'Contract_001', ' PO-GLX-2026-01', 'Original', 2026, 12, '2026-10-21', '2027-10-20', 900000.00, 'INR', 'M', true);
INSERT INTO public.ctw_contract VALUES ('Cust_00210', 'Contract_001', 'PO-NIM-2026-001', 'Original', 2026, 12, '2026-10-21', '2027-10-21', 750000.00, 'INR', 'Q', true);
INSERT INTO public.ctw_contract VALUES ('Cust_00215', 'Contract_001', 'kaouc834672', 'Original', 2026, 13, '2026-10-21', '2027-11-15', 3000.00, 'INR', 'Q', true);


--
-- Data for Name: ctw_framework; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_framework VALUES (101, 'ISO 9001:2015 (Quality Management System)', true);
INSERT INTO public.ctw_framework VALUES (102, 'ISO/IEC 27001:2022 (Information Security Management System - ISMS)', true);
INSERT INTO public.ctw_framework VALUES (103, 'DPDPA 2023 (Digital Personal Data Protection Act - India)', true);
INSERT INTO public.ctw_framework VALUES (104, 'ISO 22301:2019 (Business Continuity Management System - BCMS)', true);
INSERT INTO public.ctw_framework VALUES (105, 'ISO 31000:2018 (Risk Management Guidelines)', true);
INSERT INTO public.ctw_framework VALUES (106, 'ISO 45001:2018 (Occupational Health and Safety)', true);
INSERT INTO public.ctw_framework VALUES (107, 'NIST SP 800-53 Rev. 5 (Security and Privacy Controls)', true);
INSERT INTO public.ctw_framework VALUES (108, 'NIST Cybersecurity Framework (CSF) 2.0', true);
INSERT INTO public.ctw_framework VALUES (109, 'PCI DSS v4.0 (Payment Card Industry Data Security Standard)', true);
INSERT INTO public.ctw_framework VALUES (110, 'COBIT 2019 (Information & Technology Governance)', true);
INSERT INTO public.ctw_framework VALUES (111, 'TOGAF Standard 10th Ed. (Enterprise Architecture)', true);
INSERT INTO public.ctw_framework VALUES (112, 'ISA/IEC 62443 (Industrial Automation & Control Systems)', true);
INSERT INTO public.ctw_framework VALUES (113, 'IEC 61508 (Functional Safety)', true);
INSERT INTO public.ctw_framework VALUES (114, 'IEC 61511 (Functional Safety - Process Industry)', true);
INSERT INTO public.ctw_framework VALUES (115, 'NERC CIP (Critical Infrastructure Protection)', true);
INSERT INTO public.ctw_framework VALUES (116, 'ISO/IEC 27017:2015 (Cloud Security Controls)', true);
INSERT INTO public.ctw_framework VALUES (117, 'ISO/IEC 27701:2019 (Privacy Information Management System - PIMS)', true);
INSERT INTO public.ctw_framework VALUES (118, 'GDPR (General Data Protection Regulation - EU)', true);
INSERT INTO public.ctw_framework VALUES (119, 'EU AI Act (Artificial Intelligence Governance)', true);


--
-- Data for Name: ctw_licence; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_licence VALUES ('Cust_00101', 25, 2, 1, 20, 10, 2, '2027-03-31', '2026-10-21 05:41:28.170743+00');
INSERT INTO public.ctw_licence VALUES ('Cust_00202', 25, 2, 1, 20, 5, 2, '2027-10-20', '2026-10-21 10:50:53.561257+00');
INSERT INTO public.ctw_licence VALUES ('Cust_00206', 20, 2, 1, 10, 5, 2, '2027-10-20', '2026-10-21 11:15:56.776699+00');
INSERT INTO public.ctw_licence VALUES ('Cust_00210', 20, 2, 1, 10, 5, 2, '2027-10-20', '2026-10-21 14:40:36.811824+00');
INSERT INTO public.ctw_licence VALUES ('Cust_00215', 20, 2, 1, 4, 2, 2, '2026-10-22', '2026-10-21 16:46:48.132986+00');


--
-- Data for Name: ctw_licence_framework; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_licence_framework VALUES ('Cust_00101', 102, 12);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00101', 103, 6);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00206', 102, 12);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00206', 103, 6);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00210', 102, 12);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00210', 103, 6);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00215', 102, 12);
INSERT INTO public.ctw_licence_framework VALUES ('Cust_00215', 103, 6);


--
-- Data for Name: ctw_licence_framework_office; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00101', 102, 'Cust_00101_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00101', 102, 'Cust_00101_002');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00101', 103, 'Cust_00101_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00206', 102, 'Cust_00206_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00206', 102, 'Cust_00206_002');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00206', 103, 'Cust_00206_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00210', 102, 'Cust_00210_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00210', 102, 'Cust_00210_002');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00210', 103, 'Cust_00210_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00215', 102, 'Cust_00215_001');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00215', 102, 'Cust_00215_002');
INSERT INTO public.ctw_licence_framework_office VALUES ('Cust_00215', 103, 'Cust_00215_002');


--
-- Data for Name: ctw_licence_module; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'compliance');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'vulnerabilities');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'alerting');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'mobile_access');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'news_breach_watch');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00101', 'incidents');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00202', 'compliance');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00206', 'compliance');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00206', 'vulnerabilities');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00206', 'alerting');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00206', 'news_breach_watch');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00210', 'compliance');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00210', 'vulnerabilities');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00210', 'alerting');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00210', 'news_breach_watch');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00215', 'compliance');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00215', 'vulnerabilities');
INSERT INTO public.ctw_licence_module VALUES ('Cust_00215', 'alerting');


--
-- Data for Name: ctw_migration; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_migration VALUES ('001_ctw_schema', '2026-10-21 05:57:37.181358+00');
INSERT INTO public.ctw_migration VALUES ('002_security', '2026-10-21 05:57:37.183948+00');
INSERT INTO public.ctw_migration VALUES ('003_drafts', '2026-10-21 13:12:38.961194+00');


--
-- Data for Name: ctw_module; Type: TABLE DATA; Schema: public; Owner: ctw_admin
--

INSERT INTO public.ctw_module VALUES ('compliance', true, 0);
INSERT INTO public.ctw_module VALUES ('vulnerabilities', false, 1);
INSERT INTO public.ctw_module VALUES ('alerting', false, 2);
INSERT INTO public.ctw_module VALUES ('mobile_access', false, 3);
INSERT INTO public.ctw_module VALUES ('news_breach_watch', false, 4);
INSERT INTO public.ctw_module VALUES ('onprem_ai_assessment', false, 5);
INSERT INTO public.ctw_module VALUES ('incidents', false, 6);


--
-- Name: ctw_admin_user_admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctw_admin
--

SELECT pg_catalog.setval('public.ctw_admin_user_admin_id_seq', 7, true);


--
-- Name: ctw_audit_log_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctw_admin
--

SELECT pg_catalog.setval('public.ctw_audit_log_audit_id_seq', 193, true);


--
-- Name: ctw_build_build_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ctw_admin
--

SELECT pg_catalog.setval('public.ctw_build_build_id_seq', 12, true);


--
-- Name: ctw_admin_user ctw_admin_user_email_key; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_admin_user
    ADD CONSTRAINT ctw_admin_user_email_key UNIQUE (email);


--
-- Name: ctw_admin_user ctw_admin_user_login_id_key; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_admin_user
    ADD CONSTRAINT ctw_admin_user_login_id_key UNIQUE (login_id);


--
-- Name: ctw_admin_user ctw_admin_user_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_admin_user
    ADD CONSTRAINT ctw_admin_user_pkey PRIMARY KEY (admin_id);


--
-- Name: ctw_audit_log ctw_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_audit_log
    ADD CONSTRAINT ctw_audit_log_pkey PRIMARY KEY (audit_id);


--
-- Name: ctw_build ctw_build_customer_id_version_key; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build
    ADD CONSTRAINT ctw_build_customer_id_version_key UNIQUE (customer_id, version);


--
-- Name: ctw_build ctw_build_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build
    ADD CONSTRAINT ctw_build_pkey PRIMARY KEY (build_id);


--
-- Name: ctw_client_contact ctw_client_contact_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_contact
    ADD CONSTRAINT ctw_client_contact_pkey PRIMARY KEY (contact_id);


--
-- Name: ctw_client_initial_user ctw_client_initial_user_customer_id_login_id_key; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_initial_user
    ADD CONSTRAINT ctw_client_initial_user_customer_id_login_id_key UNIQUE (customer_id, login_id);


--
-- Name: ctw_client_initial_user ctw_client_initial_user_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_initial_user
    ADD CONSTRAINT ctw_client_initial_user_pkey PRIMARY KEY (customer_id, user_id);


--
-- Name: ctw_client_news_watch ctw_client_news_watch_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_news_watch
    ADD CONSTRAINT ctw_client_news_watch_pkey PRIMARY KEY (customer_id);


--
-- Name: ctw_client_office ctw_client_office_customer_id_office_id_key; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_office
    ADD CONSTRAINT ctw_client_office_customer_id_office_id_key UNIQUE (customer_id, office_id);


--
-- Name: ctw_client_office ctw_client_office_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_office
    ADD CONSTRAINT ctw_client_office_pkey PRIMARY KEY (office_id);


--
-- Name: ctw_client ctw_client_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client
    ADD CONSTRAINT ctw_client_pkey PRIMARY KEY (customer_id);


--
-- Name: ctw_client_security_policy ctw_client_security_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_security_policy
    ADD CONSTRAINT ctw_client_security_policy_pkey PRIMARY KEY (customer_id);


--
-- Name: ctw_client_tool ctw_client_tool_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_tool
    ADD CONSTRAINT ctw_client_tool_pkey PRIMARY KEY (customer_id, tool_name);


--
-- Name: ctw_contract ctw_contract_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_contract
    ADD CONSTRAINT ctw_contract_pkey PRIMARY KEY (customer_id, contract_id);


--
-- Name: ctw_framework ctw_framework_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_framework
    ADD CONSTRAINT ctw_framework_pkey PRIMARY KEY (framework_id);


--
-- Name: ctw_licence_framework_office ctw_licence_framework_office_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework_office
    ADD CONSTRAINT ctw_licence_framework_office_pkey PRIMARY KEY (customer_id, framework_id, office_id);


--
-- Name: ctw_licence_framework ctw_licence_framework_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework
    ADD CONSTRAINT ctw_licence_framework_pkey PRIMARY KEY (customer_id, framework_id);


--
-- Name: ctw_licence_module ctw_licence_module_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_module
    ADD CONSTRAINT ctw_licence_module_pkey PRIMARY KEY (customer_id, module_name);


--
-- Name: ctw_licence ctw_licence_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence
    ADD CONSTRAINT ctw_licence_pkey PRIMARY KEY (customer_id);


--
-- Name: ctw_migration ctw_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_migration
    ADD CONSTRAINT ctw_migration_pkey PRIMARY KEY (name);


--
-- Name: ctw_module ctw_module_pkey; Type: CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_module
    ADD CONSTRAINT ctw_module_pkey PRIMARY KEY (module_name);


--
-- Name: ctw_audit_log_at; Type: INDEX; Schema: public; Owner: ctw_admin
--

CREATE INDEX ctw_audit_log_at ON public.ctw_audit_log USING btree (at DESC);


--
-- Name: ctw_audit_log_customer; Type: INDEX; Schema: public; Owner: ctw_admin
--

CREATE INDEX ctw_audit_log_customer ON public.ctw_audit_log USING btree (customer_id, at DESC);


--
-- Name: ctw_build_customer; Type: INDEX; Schema: public; Owner: ctw_admin
--

CREATE INDEX ctw_build_customer ON public.ctw_build USING btree (customer_id, created_at DESC);


--
-- Name: ctw_client_office_one_primary; Type: INDEX; Schema: public; Owner: ctw_admin
--

CREATE UNIQUE INDEX ctw_client_office_one_primary ON public.ctw_client_office USING btree (customer_id) WHERE (office_type = 'Primary'::text);


--
-- Name: ctw_contract_one_current; Type: INDEX; Schema: public; Owner: ctw_admin
--

CREATE UNIQUE INDEX ctw_contract_one_current ON public.ctw_contract USING btree (customer_id) WHERE is_current;


--
-- Name: ctw_client ctw_client_touch; Type: TRIGGER; Schema: public; Owner: ctw_admin
--

CREATE TRIGGER ctw_client_touch BEFORE UPDATE ON public.ctw_client FOR EACH ROW EXECUTE FUNCTION public.ctw_touch_updated_at();


--
-- Name: ctw_licence ctw_licence_touch; Type: TRIGGER; Schema: public; Owner: ctw_admin
--

CREATE TRIGGER ctw_licence_touch BEFORE UPDATE ON public.ctw_licence FOR EACH ROW EXECUTE FUNCTION public.ctw_touch_updated_at();


--
-- Name: ctw_admin_user ctw_admin_user_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_admin_user
    ADD CONSTRAINT ctw_admin_user_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.ctw_admin_user(admin_id);


--
-- Name: ctw_audit_log ctw_audit_log_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_audit_log
    ADD CONSTRAINT ctw_audit_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.ctw_admin_user(admin_id);


--
-- Name: ctw_build ctw_build_based_on_build_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build
    ADD CONSTRAINT ctw_build_based_on_build_fkey FOREIGN KEY (based_on_build) REFERENCES public.ctw_build(build_id);


--
-- Name: ctw_build ctw_build_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build
    ADD CONSTRAINT ctw_build_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id);


--
-- Name: ctw_build ctw_build_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_build
    ADD CONSTRAINT ctw_build_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.ctw_admin_user(admin_id);


--
-- Name: ctw_client_contact ctw_client_contact_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_contact
    ADD CONSTRAINT ctw_client_contact_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_client_contact ctw_client_contact_customer_id_office_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_contact
    ADD CONSTRAINT ctw_client_contact_customer_id_office_id_fkey FOREIGN KEY (customer_id, office_id) REFERENCES public.ctw_client_office(customer_id, office_id);


--
-- Name: ctw_client ctw_client_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client
    ADD CONSTRAINT ctw_client_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.ctw_admin_user(admin_id);


--
-- Name: ctw_client_initial_user ctw_client_initial_user_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_initial_user
    ADD CONSTRAINT ctw_client_initial_user_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_client_initial_user ctw_client_initial_user_customer_id_office_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_initial_user
    ADD CONSTRAINT ctw_client_initial_user_customer_id_office_id_fkey FOREIGN KEY (customer_id, office_id) REFERENCES public.ctw_client_office(customer_id, office_id);


--
-- Name: ctw_client_news_watch ctw_client_news_watch_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_news_watch
    ADD CONSTRAINT ctw_client_news_watch_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_client_office ctw_client_office_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_office
    ADD CONSTRAINT ctw_client_office_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_client_security_policy ctw_client_security_policy_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_security_policy
    ADD CONSTRAINT ctw_client_security_policy_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_client_tool ctw_client_tool_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_client_tool
    ADD CONSTRAINT ctw_client_tool_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_contract ctw_contract_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_contract
    ADD CONSTRAINT ctw_contract_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_licence ctw_licence_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence
    ADD CONSTRAINT ctw_licence_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_client(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_licence_framework ctw_licence_framework_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework
    ADD CONSTRAINT ctw_licence_framework_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_licence(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_licence_framework ctw_licence_framework_framework_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework
    ADD CONSTRAINT ctw_licence_framework_framework_id_fkey FOREIGN KEY (framework_id) REFERENCES public.ctw_framework(framework_id);


--
-- Name: ctw_licence_framework_office ctw_licence_framework_office_customer_id_framework_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework_office
    ADD CONSTRAINT ctw_licence_framework_office_customer_id_framework_id_fkey FOREIGN KEY (customer_id, framework_id) REFERENCES public.ctw_licence_framework(customer_id, framework_id) ON DELETE CASCADE;


--
-- Name: ctw_licence_framework_office ctw_licence_framework_office_customer_id_office_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_framework_office
    ADD CONSTRAINT ctw_licence_framework_office_customer_id_office_id_fkey FOREIGN KEY (customer_id, office_id) REFERENCES public.ctw_client_office(customer_id, office_id) ON DELETE CASCADE;


--
-- Name: ctw_licence_module ctw_licence_module_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_module
    ADD CONSTRAINT ctw_licence_module_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.ctw_licence(customer_id) ON DELETE CASCADE;


--
-- Name: ctw_licence_module ctw_licence_module_module_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ctw_admin
--

ALTER TABLE ONLY public.ctw_licence_module
    ADD CONSTRAINT ctw_licence_module_module_name_fkey FOREIGN KEY (module_name) REFERENCES public.ctw_module(module_name);


--
-- PostgreSQL database dump complete
--

\unrestrict MXAAZ7YjfdGX2vGCu7yzUNK2cTpAVgWJbjZsIyOeXIHAipocnw91JlUvEzNNfxV

