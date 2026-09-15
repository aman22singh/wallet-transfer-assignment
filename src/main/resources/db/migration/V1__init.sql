CREATE TABLE wallets (
    id          VARCHAR(64)     PRIMARY KEY,
    balance     NUMERIC(19,4)   NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT chk_wallets_balance_non_negative CHECK (balance >= 0)
);

CREATE TABLE transfers (
    id               UUID            PRIMARY KEY,
    idempotency_key  VARCHAR(255)    NOT NULL,
    from_wallet_id   VARCHAR(64)     NOT NULL REFERENCES wallets(id),
    to_wallet_id     VARCHAR(64)     NOT NULL REFERENCES wallets(id),
    amount           NUMERIC(19,4)   NOT NULL,
    status           VARCHAR(16)     NOT NULL,
    failure_reason   VARCHAR(512),
    created_at       TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT uq_transfers_idempotency_key UNIQUE (idempotency_key),
    CONSTRAINT chk_transfers_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_transfers_distinct_wallets CHECK (from_wallet_id <> to_wallet_id),
    CONSTRAINT chk_transfers_status CHECK (status IN ('PENDING', 'PROCESSED', 'FAILED'))
);

CREATE INDEX idx_transfers_from_wallet ON transfers(from_wallet_id);
CREATE INDEX idx_transfers_to_wallet   ON transfers(to_wallet_id);

CREATE TABLE ledger_entries (
    id           UUID            PRIMARY KEY,
    transfer_id  UUID            NOT NULL REFERENCES transfers(id),
    wallet_id    VARCHAR(64)     NOT NULL REFERENCES wallets(id),
    entry_type   VARCHAR(8)      NOT NULL,
    amount       NUMERIC(19,4)   NOT NULL,
    created_at   TIMESTAMPTZ     NOT NULL DEFAULT now(),
    CONSTRAINT chk_ledger_entry_type CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    CONSTRAINT chk_ledger_amount_positive CHECK (amount > 0)
);

CREATE INDEX idx_ledger_entries_wallet_id   ON ledger_entries(wallet_id);
CREATE INDEX idx_ledger_entries_transfer_id ON ledger_entries(transfer_id);

CREATE TABLE idempotency_records (
    idempotency_key  VARCHAR(255)   PRIMARY KEY,
    request_hash     VARCHAR(128)   NOT NULL,
    transfer_id      UUID           REFERENCES transfers(id),
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ    NOT NULL DEFAULT now()
);

-- Seed a couple of wallets for local manual testing / curl-ing the API.
INSERT INTO wallets (id, balance) VALUES
    ('wallet_1', 1000.0000),
    ('wallet_2', 500.0000),
    ('wallet_3', 0.0000);
