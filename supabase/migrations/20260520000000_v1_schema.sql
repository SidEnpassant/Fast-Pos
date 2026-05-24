-- Fast-Pos v1.0 schema extensions

-- Products / inventory
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  sku text,
  barcode text,
  price numeric NOT NULL DEFAULT 0,
  cost_price numeric,
  stock_quantity int NOT NULL DEFAULT 0,
  min_stock_threshold int NOT NULL DEFAULT 5,
  category text,
  is_active boolean NOT NULL DEFAULT true,
  velocity_ema numeric NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, barcode)
);

-- Expenses
CREATE TABLE IF NOT EXISTS public.expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL,
  amount numeric NOT NULL,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Customers
CREATE TABLE IF NOT EXISTS public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text,
  credit_balance numeric NOT NULL DEFAULT 0,
  loyalty_points int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Customer ledger
CREATE TABLE IF NOT EXISTS public.customer_ledger_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  bill_id uuid REFERENCES public.bills(id) ON DELETE SET NULL,
  type text NOT NULL CHECK (type IN ('debit', 'credit', 'payment')),
  amount numeric NOT NULL,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Bill audit hashes
CREATE TABLE IF NOT EXISTS public.bill_audit (
  bill_id uuid PRIMARY KEY REFERENCES public.bills(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  payload_hash text NOT NULL,
  algorithm text NOT NULL DEFAULT 'sha256',
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Extend bills for offline sync
ALTER TABLE public.bills ADD COLUMN IF NOT EXISTS client_id uuid;
ALTER TABLE public.bills ADD COLUMN IF NOT EXISTS sync_status text DEFAULT 'synced';
ALTER TABLE public.bills ADD COLUMN IF NOT EXISTS content_hash text;
ALTER TABLE public.bills ADD COLUMN IF NOT EXISTS customer_id uuid REFERENCES public.customers(id);
ALTER TABLE public.bills ADD COLUMN IF NOT EXISTS discount_breakdown jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS bills_user_client_id_idx
  ON public.bills (user_id, client_id) WHERE client_id IS NOT NULL;

-- RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY products_user ON public.products FOR ALL USING (auth.uid() = user_id);
CREATE POLICY expenses_user ON public.expenses FOR ALL USING (auth.uid() = user_id);
CREATE POLICY customers_user ON public.customers FOR ALL USING (auth.uid() = user_id);
CREATE POLICY ledger_user ON public.customer_ledger_entries FOR ALL
  USING (EXISTS (SELECT 1 FROM public.customers c WHERE c.id = customer_id AND c.user_id = auth.uid()));
CREATE POLICY bill_audit_user ON public.bill_audit FOR ALL USING (auth.uid() = user_id);

-- Atomic stock decrement
CREATE OR REPLACE FUNCTION public.decrement_stock_atomic(p_product_id uuid, p_qty int)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_qty int;
BEGIN
  UPDATE public.products
  SET stock_quantity = stock_quantity - p_qty,
      updated_at = now()
  WHERE id = p_product_id
    AND user_id = auth.uid()
    AND stock_quantity >= p_qty
  RETURNING stock_quantity INTO new_qty;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient stock or product not found';
  END IF;

  RETURN new_qty;
END;
$$;

-- Bulk product upsert
CREATE OR REPLACE FUNCTION public.bulk_upsert_products(p_user_id uuid, p_json jsonb)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  cnt int := 0;
  row jsonb;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  FOR row IN SELECT * FROM jsonb_array_elements(p_json)
  LOOP
    INSERT INTO public.products (
      user_id, name, sku, barcode, price, cost_price,
      stock_quantity, min_stock_threshold, category, is_active, updated_at
    ) VALUES (
      p_user_id,
      row->>'name',
      row->>'sku',
      row->>'barcode',
      COALESCE((row->>'price')::numeric, 0),
      (row->>'cost_price')::numeric,
      COALESCE((row->>'stock_quantity')::int, 0),
      COALESCE((row->>'min_stock_threshold')::int, 5),
      row->>'category',
      COALESCE((row->>'is_active')::boolean, true),
      now()
    )
    ON CONFLICT (user_id, barcode) DO UPDATE SET
      name = EXCLUDED.name,
      sku = EXCLUDED.sku,
      price = EXCLUDED.price,
      cost_price = EXCLUDED.cost_price,
      stock_quantity = EXCLUDED.stock_quantity,
      min_stock_threshold = EXCLUDED.min_stock_threshold,
      category = EXCLUDED.category,
      is_active = EXCLUDED.is_active,
      updated_at = now();
    cnt := cnt + 1;
  END LOOP;

  RETURN cnt;
END;
$$;

-- Low stock notification trigger
CREATE OR REPLACE FUNCTION public.notify_low_stock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.stock_quantity <= NEW.min_stock_threshold THEN
    INSERT INTO public.notifications (user_id, message, is_read)
    VALUES (
      NEW.user_id,
      'Low stock alert: ' || NEW.name || ' (' || NEW.stock_quantity || ' left)',
      false
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS products_low_stock ON public.products;
CREATE TRIGGER products_low_stock
  AFTER UPDATE OF stock_quantity ON public.products
  FOR EACH ROW
  WHEN (NEW.stock_quantity <= NEW.min_stock_threshold)
  EXECUTE FUNCTION public.notify_low_stock();
