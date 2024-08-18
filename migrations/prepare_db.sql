TRUNCATE TABLE staging.user_order_log;

DO $$
BEGIN
    -- Проверка и добавление столбца 'status' в таблицу 'staging.user_order_log'
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'staging'
        AND table_name = 'user_order_log'
        AND column_name = 'status'
    ) THEN
        EXECUTE 'ALTER TABLE staging.user_order_log ADD COLUMN status VARCHAR(8) NOT NULL DEFAULT ''shipped''';
    END IF;
    
    -- Проверка и добавление столбца 'status' в таблицу 'mart.f_sales'
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'mart'
        AND table_name = 'f_sales'
        AND column_name = 'status'
    ) THEN
        EXECUTE 'ALTER TABLE mart.f_sales ADD COLUMN status VARCHAR(8) NOT NULL DEFAULT ''shipped''';
    END IF;
END $$;