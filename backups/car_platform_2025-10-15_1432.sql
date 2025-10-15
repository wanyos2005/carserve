--
-- PostgreSQL database dump
--

\restrict PM5umsasU6xPZXbS7EcwimIRTCJmAcR2NDb4VdReNi1bhejGnT3p5JxDKVM2aLy

-- Dumped from database version 15.14
-- Dumped by pg_dump version 15.14

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
-- Name: alerts; Type: SCHEMA; Schema: -; Owner: AdminDb
--

CREATE SCHEMA alerts;


ALTER SCHEMA alerts OWNER TO "AdminDb";

--
-- Name: users; Type: SCHEMA; Schema: -; Owner: AdminDb
--

CREATE SCHEMA users;


ALTER SCHEMA users OWNER TO "AdminDb";

--
-- Name: alertchannel; Type: TYPE; Schema: public; Owner: AdminDb
--

CREATE TYPE public.alertchannel AS ENUM (
    'IN_APP',
    'PUSH',
    'SMS',
    'EMAIL',
    'WHATSAPP'
);


ALTER TYPE public.alertchannel OWNER TO "AdminDb";

--
-- Name: alertstatus; Type: TYPE; Schema: public; Owner: AdminDb
--

CREATE TYPE public.alertstatus AS ENUM (
    'PENDING',
    'SENT',
    'DELIVERED',
    'FAILED',
    'CANCELLED'
);


ALTER TYPE public.alertstatus OWNER TO "AdminDb";

--
-- Name: alerttype; Type: TYPE; Schema: public; Owner: AdminDb
--

CREATE TYPE public.alerttype AS ENUM (
    'INSURANCE_EXPIRY',
    'SERVICE_DUE',
    'PROMOTIONAL',
    'MAINTENANCE_REMINDER',
    'CLAIM_UPDATE',
    'PAYMENT_REMINDER'
);


ALTER TYPE public.alerttype OWNER TO "AdminDb";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: alerts; Owner: AdminDb
--

CREATE TABLE alerts.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE alerts.alembic_version OWNER TO "AdminDb";

--
-- Name: alert_preferences; Type: TABLE; Schema: alerts; Owner: AdminDb
--

CREATE TABLE alerts.alert_preferences (
    id character varying NOT NULL,
    user_id integer NOT NULL,
    alert_type public.alerttype NOT NULL,
    is_enabled boolean,
    channels json NOT NULL,
    frequency character varying,
    quiet_hours_start character varying,
    quiet_hours_end character varying,
    timezone character varying,
    min_priority integer,
    batch_alerts boolean,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE alerts.alert_preferences OWNER TO "AdminDb";

--
-- Name: alert_rules; Type: TABLE; Schema: alerts; Owner: AdminDb
--

CREATE TABLE alerts.alert_rules (
    id character varying NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    alert_type public.alerttype NOT NULL,
    trigger_conditions json NOT NULL,
    message_template text NOT NULL,
    title_template character varying(255) NOT NULL,
    channels json NOT NULL,
    priority integer,
    is_active boolean,
    schedule_expression character varying,
    created_by character varying,
    version character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE alerts.alert_rules OWNER TO "AdminDb";

--
-- Name: alerts; Type: TABLE; Schema: alerts; Owner: AdminDb
--

CREATE TABLE alerts.alerts (
    id character varying NOT NULL,
    user_id integer NOT NULL,
    type public.alerttype NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    priority integer,
    vehicle_id character varying,
    policy_id character varying,
    booking_id character varying,
    provider_id character varying,
    channels json NOT NULL,
    status public.alertstatus,
    scheduled_at timestamp with time zone,
    sent_at timestamp with time zone,
    delivered_at timestamp with time zone,
    action_url character varying,
    action_text character varying,
    alert_metadata json,
    retry_count integer,
    max_retries integer,
    error_message text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE alerts.alerts OWNER TO "AdminDb";

--
-- Name: notification_logs; Type: TABLE; Schema: alerts; Owner: AdminDb
--

CREATE TABLE alerts.notification_logs (
    id character varying NOT NULL,
    alert_id character varying,
    user_id integer NOT NULL,
    channel public.alertchannel NOT NULL,
    status public.alertstatus NOT NULL,
    external_id character varying,
    external_response json,
    sent_at timestamp with time zone DEFAULT now(),
    delivered_at timestamp with time zone,
    error_message text,
    retry_count integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE alerts.notification_logs OWNER TO "AdminDb";

--
-- Name: alembic_version; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE users.alembic_version OWNER TO "AdminDb";

--
-- Name: provider_user_links; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.provider_user_links (
    id integer NOT NULL,
    user_id integer NOT NULL,
    provider_id character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE users.provider_user_links OWNER TO "AdminDb";

--
-- Name: provider_user_links_id_seq; Type: SEQUENCE; Schema: users; Owner: AdminDb
--

CREATE SEQUENCE users.provider_user_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users.provider_user_links_id_seq OWNER TO "AdminDb";

--
-- Name: provider_user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: users; Owner: AdminDb
--

ALTER SEQUENCE users.provider_user_links_id_seq OWNED BY users.provider_user_links.id;


--
-- Name: tbl_auth; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.tbl_auth (
    id integer NOT NULL,
    email character varying,
    name character varying,
    phone character varying,
    auth_provider character varying,
    verified boolean,
    is_guest boolean,
    created_by_provider_id character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE users.tbl_auth OWNER TO "AdminDb";

--
-- Name: tbl_auth_id_seq; Type: SEQUENCE; Schema: users; Owner: AdminDb
--

CREATE SEQUENCE users.tbl_auth_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users.tbl_auth_id_seq OWNER TO "AdminDb";

--
-- Name: tbl_auth_id_seq; Type: SEQUENCE OWNED BY; Schema: users; Owner: AdminDb
--

ALTER SEQUENCE users.tbl_auth_id_seq OWNED BY users.tbl_auth.id;


--
-- Name: tbl_auth_roles; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.tbl_auth_roles (
    id uuid NOT NULL,
    user_id integer,
    role_id character varying NOT NULL,
    active boolean,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE users.tbl_auth_roles OWNER TO "AdminDb";

--
-- Name: tbl_otp; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.tbl_otp (
    id integer NOT NULL,
    email character varying NOT NULL,
    code character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE users.tbl_otp OWNER TO "AdminDb";

--
-- Name: tbl_otp_id_seq; Type: SEQUENCE; Schema: users; Owner: AdminDb
--

CREATE SEQUENCE users.tbl_otp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users.tbl_otp_id_seq OWNER TO "AdminDb";

--
-- Name: tbl_otp_id_seq; Type: SEQUENCE OWNED BY; Schema: users; Owner: AdminDb
--

ALTER SEQUENCE users.tbl_otp_id_seq OWNED BY users.tbl_otp.id;


--
-- Name: tbl_roles; Type: TABLE; Schema: users; Owner: AdminDb
--

CREATE TABLE users.tbl_roles (
    id uuid NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE users.tbl_roles OWNER TO "AdminDb";

--
-- Name: provider_user_links id; Type: DEFAULT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.provider_user_links ALTER COLUMN id SET DEFAULT nextval('users.provider_user_links_id_seq'::regclass);


--
-- Name: tbl_auth id; Type: DEFAULT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_auth ALTER COLUMN id SET DEFAULT nextval('users.tbl_auth_id_seq'::regclass);


--
-- Name: tbl_otp id; Type: DEFAULT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_otp ALTER COLUMN id SET DEFAULT nextval('users.tbl_otp_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: alerts; Owner: AdminDb
--

COPY alerts.alembic_version (version_num) FROM stdin;
3ba7726e485a
\.


--
-- Data for Name: alert_preferences; Type: TABLE DATA; Schema: alerts; Owner: AdminDb
--

COPY alerts.alert_preferences (id, user_id, alert_type, is_enabled, channels, frequency, quiet_hours_start, quiet_hours_end, timezone, min_priority, batch_alerts, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: alerts; Owner: AdminDb
--

COPY alerts.alert_rules (id, name, description, alert_type, trigger_conditions, message_template, title_template, channels, priority, is_active, schedule_expression, created_by, version, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: alerts; Owner: AdminDb
--

COPY alerts.alerts (id, user_id, type, title, message, priority, vehicle_id, policy_id, booking_id, provider_id, channels, status, scheduled_at, sent_at, delivered_at, action_url, action_text, alert_metadata, retry_count, max_retries, error_message, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notification_logs; Type: TABLE DATA; Schema: alerts; Owner: AdminDb
--

COPY alerts.notification_logs (id, alert_id, user_id, channel, status, external_id, external_response, sent_at, delivered_at, error_message, retry_count, created_at) FROM stdin;
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.alembic_version (version_num) FROM stdin;
62f6505a8b68
\.


--
-- Data for Name: provider_user_links; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.provider_user_links (id, user_id, provider_id, created_at) FROM stdin;
\.


--
-- Data for Name: tbl_auth; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.tbl_auth (id, email, name, phone, auth_provider, verified, is_guest, created_by_provider_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tbl_auth_roles; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.tbl_auth_roles (id, user_id, role_id, active, created_at) FROM stdin;
\.


--
-- Data for Name: tbl_otp; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.tbl_otp (id, email, code, expires_at, created_at) FROM stdin;
\.


--
-- Data for Name: tbl_roles; Type: TABLE DATA; Schema: users; Owner: AdminDb
--

COPY users.tbl_roles (id, name, created_at) FROM stdin;
\.


--
-- Name: provider_user_links_id_seq; Type: SEQUENCE SET; Schema: users; Owner: AdminDb
--

SELECT pg_catalog.setval('users.provider_user_links_id_seq', 1, false);


--
-- Name: tbl_auth_id_seq; Type: SEQUENCE SET; Schema: users; Owner: AdminDb
--

SELECT pg_catalog.setval('users.tbl_auth_id_seq', 1, false);


--
-- Name: tbl_otp_id_seq; Type: SEQUENCE SET; Schema: users; Owner: AdminDb
--

SELECT pg_catalog.setval('users.tbl_otp_id_seq', 1, false);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: alert_preferences alert_preferences_pkey; Type: CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.alert_preferences
    ADD CONSTRAINT alert_preferences_pkey PRIMARY KEY (id);


--
-- Name: alert_rules alert_rules_pkey; Type: CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: provider_user_links provider_user_links_pkey; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.provider_user_links
    ADD CONSTRAINT provider_user_links_pkey PRIMARY KEY (id);


--
-- Name: tbl_auth tbl_auth_pkey; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_auth
    ADD CONSTRAINT tbl_auth_pkey PRIMARY KEY (id);


--
-- Name: tbl_auth_roles tbl_auth_roles_pkey; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_auth_roles
    ADD CONSTRAINT tbl_auth_roles_pkey PRIMARY KEY (id);


--
-- Name: tbl_otp tbl_otp_pkey; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_otp
    ADD CONSTRAINT tbl_otp_pkey PRIMARY KEY (id);


--
-- Name: tbl_roles tbl_roles_pkey; Type: CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_roles
    ADD CONSTRAINT tbl_roles_pkey PRIMARY KEY (id);


--
-- Name: ix_alerts_alert_preferences_alert_type; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alert_preferences_alert_type ON alerts.alert_preferences USING btree (alert_type);


--
-- Name: ix_alerts_alert_preferences_user_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alert_preferences_user_id ON alerts.alert_preferences USING btree (user_id);


--
-- Name: ix_alerts_alerts_booking_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_booking_id ON alerts.alerts USING btree (booking_id);


--
-- Name: ix_alerts_alerts_policy_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_policy_id ON alerts.alerts USING btree (policy_id);


--
-- Name: ix_alerts_alerts_provider_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_provider_id ON alerts.alerts USING btree (provider_id);


--
-- Name: ix_alerts_alerts_status; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_status ON alerts.alerts USING btree (status);


--
-- Name: ix_alerts_alerts_type; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_type ON alerts.alerts USING btree (type);


--
-- Name: ix_alerts_alerts_user_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_user_id ON alerts.alerts USING btree (user_id);


--
-- Name: ix_alerts_alerts_vehicle_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_alerts_vehicle_id ON alerts.alerts USING btree (vehicle_id);


--
-- Name: ix_alerts_notification_logs_alert_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_notification_logs_alert_id ON alerts.notification_logs USING btree (alert_id);


--
-- Name: ix_alerts_notification_logs_user_id; Type: INDEX; Schema: alerts; Owner: AdminDb
--

CREATE INDEX ix_alerts_notification_logs_user_id ON alerts.notification_logs USING btree (user_id);


--
-- Name: ix_users_tbl_auth_auth_provider; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_auth_auth_provider ON users.tbl_auth USING btree (auth_provider);


--
-- Name: ix_users_tbl_auth_email; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE UNIQUE INDEX ix_users_tbl_auth_email ON users.tbl_auth USING btree (email);


--
-- Name: ix_users_tbl_auth_id; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_auth_id ON users.tbl_auth USING btree (id);


--
-- Name: ix_users_tbl_auth_name; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_auth_name ON users.tbl_auth USING btree (name);


--
-- Name: ix_users_tbl_auth_phone; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_auth_phone ON users.tbl_auth USING btree (phone);


--
-- Name: ix_users_tbl_otp_email; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_otp_email ON users.tbl_otp USING btree (email);


--
-- Name: ix_users_tbl_otp_id; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_otp_id ON users.tbl_otp USING btree (id);


--
-- Name: ix_users_tbl_roles_name; Type: INDEX; Schema: users; Owner: AdminDb
--

CREATE INDEX ix_users_tbl_roles_name ON users.tbl_roles USING btree (name);


--
-- Name: notification_logs notification_logs_alert_id_fkey; Type: FK CONSTRAINT; Schema: alerts; Owner: AdminDb
--

ALTER TABLE ONLY alerts.notification_logs
    ADD CONSTRAINT notification_logs_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES alerts.alerts(id);


--
-- Name: provider_user_links provider_user_links_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.provider_user_links
    ADD CONSTRAINT provider_user_links_user_id_fkey FOREIGN KEY (user_id) REFERENCES users.tbl_auth(id);


--
-- Name: tbl_auth_roles tbl_auth_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: AdminDb
--

ALTER TABLE ONLY users.tbl_auth_roles
    ADD CONSTRAINT tbl_auth_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users.tbl_auth(id);


--
-- PostgreSQL database dump complete
--

\unrestrict PM5umsasU6xPZXbS7EcwimIRTCJmAcR2NDb4VdReNi1bhejGnT3p5JxDKVM2aLy

