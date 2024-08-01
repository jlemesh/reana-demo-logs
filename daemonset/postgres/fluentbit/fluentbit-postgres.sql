CREATE TABLE IF NOT EXISTS __reana.job_log
(
    "time" character varying COLLATE pg_catalog."default" NOT NULL,
    log character varying COLLATE pg_catalog."default",
    job_id_ uuid NOT NULL,
    CONSTRAINT job FOREIGN KEY (job_id_)
        REFERENCES __reana.job (id_) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS __reana.job_log
    OWNER to reana;

CREATE INDEX backend_job_id
    ON __reana.job USING btree
    (backend_job_id ASC NULLS LAST)
    WITH (deduplicate_items=False)
;

CREATE OR REPLACE FUNCTION __reana.job_logs()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
INSERT INTO job_log (job_id_, "time", "log")
SELECT id_,
NEW.time,
NEW.data::json->>'log'
FROM __reana.job
WHERE backend_job_id = NEW.data::json->'kubernetes'->'labels'->>'job-name';
RETURN NULL;
END;
$BODY$;

ALTER FUNCTION __reana.job_logs()
    OWNER TO reana;


CREATE OR REPLACE TRIGGER job_logs_tr
    BEFORE INSERT
    ON __reana.fluentbit
    FOR EACH ROW
    EXECUTE FUNCTION __reana.job_logs();


CREATE OR REPLACE FUNCTION __reana.workflow_logs()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
BEGIN
INSERT INTO workflow_log VALUES (uuid(NEW.data::json->'kubernetes'->'labels'->>'reana-run-batch-workflow-uuid'), NEW.time, NEW.data::json->>'log');
RETURN NULL;
END;
$BODY$;

ALTER FUNCTION __reana.workflow_logs()
    OWNER TO reana;


CREATE OR REPLACE TRIGGER workflow_logs_tr
    BEFORE INSERT
    ON __reana.fluentbit1
    FOR EACH ROW
    EXECUTE FUNCTION __reana.workflow_logs();

CREATE TABLE IF NOT EXISTS __reana.workflow_log
(
	workflow_id_ uuid NOT NULL,
    "time" character varying COLLATE pg_catalog."default" NOT NULL,
    log character varying COLLATE pg_catalog."default",
    CONSTRAINT workflow FOREIGN KEY (workflow_id_)
        REFERENCES __reana.workflow (id_) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS __reana.workflow_log
    OWNER to reana;
