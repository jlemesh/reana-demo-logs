CREATE TABLE IF NOT EXISTS __reana.job_log
(
    pod character varying COLLATE pg_catalog."default",
    "time" character varying COLLATE pg_catalog."default",
    tag character varying COLLATE pg_catalog."default",
    log character varying COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS __reana.job_log
    OWNER to reana;

CREATE TABLE IF NOT EXISTS __reana.workflow_log
(
    "time" character varying COLLATE pg_catalog."default",
    tag character varying COLLATE pg_catalog."default",
    log character varying COLLATE pg_catalog."default",
    workflow_id uuid,
    CONSTRAINT workflow_id_fk FOREIGN KEY (workflow_id)
        REFERENCES __reana.workflow (id_) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS __reana.workflow_log
    OWNER to reana;
