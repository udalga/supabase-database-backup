

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."check_if_admin"() RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid() AND role_id = 1 -- Varsayım: Admin rolünün ID'si 1
  );
$$;


ALTER FUNCTION "public"."check_if_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."decrease_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_decrease" numeric) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE branch_ingredient_stock
    SET stock_level = stock_level - p_quantity_to_decrease,
        updated_at = NOW()
    WHERE branch_id = p_branch_id AND ingredient_id = p_ingredient_id;
END;
$$;


ALTER FUNCTION "public"."decrease_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_decrease" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_sales_last_hour"("target_branch_id" integer) RETURNS TABLE("total_amount" numeric, "transaction_count" bigint)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(s.total_amount), 0) AS total_amount,
    COUNT(s.id) AS transaction_count
  FROM sales s
  WHERE s.branch_id = target_branch_id
    AND s.sale_time >= (timezone('utc', now()) - interval '1 hour')
    AND s.sale_time < timezone('utc', now()); -- To avoid including future data if there's any theoretical clock drift
END;
$$;


ALTER FUNCTION "public"."get_sales_last_hour"("target_branch_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_role"() RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  user_role_id INT;
BEGIN
  SELECT role_id INTO user_role_id FROM public.profiles WHERE id = auth.uid();
  RETURN user_role_id;
END;
$$;


ALTER FUNCTION "public"."get_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_inventory_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  NEW.last_updated = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_inventory_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_role_id INT;
BEGIN
  -- Varsayılan olarak atanacak rolü belirle (Örn: Kasiyer). ID'sini roles tablosundan al.
  -- Eğer rol bulunamazsa veya varsayılan rol istemiyorsanız NULL bırakabilirsiniz.
  SELECT id INTO new_role_id FROM public.roles WHERE name = 'Kasiyer' LIMIT 1; -- 'Kasiyer' rolünün ID'sini bul

  INSERT INTO public.profiles (id, role_id)
  VALUES (NEW.id, new_role_id); -- Yeni kullanıcı ID'si ve varsayılan rol ID'si ile ekle
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_product_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_product_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_profile_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_profile_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increase_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_increase" numeric) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    UPDATE branch_ingredient_stock
    SET stock_level = stock_level + p_quantity_to_increase,
        updated_at = NOW()
    WHERE branch_id = p_branch_id AND ingredient_id = p_ingredient_id;

    IF NOT FOUND THEN
        INSERT INTO branch_ingredient_stock (branch_id, ingredient_id, stock_level, updated_at, created_at)
        VALUES (p_branch_id, p_ingredient_id, p_quantity_to_increase, NOW(), NOW());
    END IF;
END;
$$;


ALTER FUNCTION "public"."increase_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_increase" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."moddatetime"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."moddatetime"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."moddatetime"() IS 'Trigger function to update the updated_at column to the current timestamp.';



CREATE OR REPLACE FUNCTION "public"."trigger_set_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_set_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
    BEGIN
       NEW.updated_at = now();
       RETURN NEW;
    END;
    $$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."branch_entity_status" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "entity_id" "uuid" NOT NULL,
    "entity_type" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "branch_entity_status_entity_type_check" CHECK (("entity_type" = ANY (ARRAY['product'::"text", 'category'::"text"])))
);


ALTER TABLE "public"."branch_entity_status" OWNER TO "postgres";


COMMENT ON TABLE "public"."branch_entity_status" IS 'Ürünlerin ve kategorilerin şube bazlı aktif/pasif durumlarını tutar.';



COMMENT ON COLUMN "public"."branch_entity_status"."entity_id" IS 'Aktif/pasif durumu belirlenen ürünün veya kategorinin IDsi.';



COMMENT ON COLUMN "public"."branch_entity_status"."entity_type" IS 'Durumu belirlenen varlığın tipi (product veya category).';



CREATE TABLE IF NOT EXISTS "public"."branch_ingredient_stock" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "stock_level" numeric DEFAULT 0 NOT NULL,
    "low_stock_threshold" numeric DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."branch_ingredient_stock" OWNER TO "postgres";


COMMENT ON TABLE "public"."branch_ingredient_stock" IS 'Malzemelerin şube bazlı stok seviyelerini tutar.';



COMMENT ON COLUMN "public"."branch_ingredient_stock"."stock_level" IS 'Malzemenin ilgili şubedeki mevcut stok miktarı.';



COMMENT ON COLUMN "public"."branch_ingredient_stock"."low_stock_threshold" IS 'Düşük stok uyarısı tetiklenecek miktar eşiği.';



CREATE TABLE IF NOT EXISTS "public"."branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "address" "text",
    "phone_number" character varying(50),
    "slug" "text"
);


ALTER TABLE "public"."branches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ingredients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "unit" "text" NOT NULL,
    "stock_quantity" numeric(10,2) DEFAULT 0.00,
    "low_stock_threshold" numeric(10,2) DEFAULT 0.00,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "ingredients_unit_check" CHECK (("unit" = ANY (ARRAY['kg'::"text", 'g'::"text", 'litre'::"text", 'ml'::"text", 'adet'::"text", 'paket'::"text", 'kutu'::"text"])))
);


ALTER TABLE "public"."ingredients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inventory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "product_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "quantity" integer DEFAULT 0 NOT NULL,
    "last_updated" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_quantity_check" CHECK (("quantity" >= 0))
);


ALTER TABLE "public"."inventory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_methods" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."payment_methods" OWNER TO "postgres";


COMMENT ON TABLE "public"."payment_methods" IS 'Uygulamada kullanılacak ödeme yöntemlerini tanımlar.';



COMMENT ON COLUMN "public"."payment_methods"."name" IS 'Ödeme yönteminin adı (örn: Nakit, Kredi Kartı).';



COMMENT ON COLUMN "public"."payment_methods"."description" IS 'Ödeme yöntemi hakkında ek bilgi (örn: Geçerli kartlar, komisyon vb).';



COMMENT ON COLUMN "public"."payment_methods"."is_active" IS 'Ödeme yönteminin şu anda aktif olup olmadığını belirtir.';



CREATE TABLE IF NOT EXISTS "public"."product_ingredients" (
    "product_id" "uuid" NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "quantity_required" numeric NOT NULL,
    CONSTRAINT "product_ingredients_quantity_required_check" CHECK (("quantity_required" > (0)::numeric))
);


ALTER TABLE "public"."product_ingredients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "description" "text",
    "price" numeric(10,2) NOT NULL,
    "category_id" "uuid",
    "sku" character varying(100),
    "image_url" "text",
    "is_active" boolean DEFAULT true NOT NULL,
    "branch_id" "uuid",
    CONSTRAINT "products_price_check" CHECK (("price" >= (0)::numeric))
);


ALTER TABLE "public"."products" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "full_name" character varying(255),
    "role_id" integer,
    "assigned_branch_id" "uuid"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" integer NOT NULL,
    "name" character varying(50) NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."roles_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."roles_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."roles_id_seq" OWNED BY "public"."roles"."id";



CREATE TABLE IF NOT EXISTS "public"."sale_item_ingredients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_item_id" "uuid" NOT NULL,
    "ingredient_id" "uuid" NOT NULL,
    "quantity_deducted" numeric(10,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "sale_item_ingredients_quantity_deducted_check" CHECK (("quantity_deducted" > (0)::numeric))
);


ALTER TABLE "public"."sale_item_ingredients" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sale_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "product_id" "uuid",
    "quantity" integer NOT NULL,
    "price_at_sale" numeric(10,2) NOT NULL,
    CONSTRAINT "sale_items_price_at_sale_check" CHECK (("price_at_sale" >= (0)::numeric)),
    CONSTRAINT "sale_items_quantity_check" CHECK (("quantity" > 0))
);


ALTER TABLE "public"."sale_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "profile_id" "uuid",
    "payment_method_id" "uuid",
    "total_amount" numeric(10,2) NOT NULL,
    "sale_time" timestamp with time zone DEFAULT "now"(),
    "branch_id" "uuid",
    CONSTRAINT "sales_total_amount_check" CHECK (("total_amount" >= (0)::numeric))
);


ALTER TABLE "public"."sales" OWNER TO "postgres";


COMMENT ON COLUMN "public"."sales"."branch_id" IS 'Satışın yapıldığı şubenin IDsi';



ALTER TABLE ONLY "public"."roles" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."roles_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."branch_entity_status"
    ADD CONSTRAINT "branch_entity_status_branch_id_entity_id_entity_type_key" UNIQUE ("branch_id", "entity_id", "entity_type");



ALTER TABLE ONLY "public"."branch_entity_status"
    ADD CONSTRAINT "branch_entity_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branch_ingredient_stock"
    ADD CONSTRAINT "branch_ingredient_stock_branch_id_ingredient_id_key" UNIQUE ("branch_id", "ingredient_id");



ALTER TABLE ONLY "public"."branch_ingredient_stock"
    ADD CONSTRAINT "branch_ingredient_stock_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ingredients"
    ADD CONSTRAINT "ingredients_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."ingredients"
    ADD CONSTRAINT "ingredients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_product_id_branch_id_key" UNIQUE ("product_id", "branch_id");



ALTER TABLE ONLY "public"."payment_methods"
    ADD CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."product_ingredients"
    ADD CONSTRAINT "product_ingredients_pkey" PRIMARY KEY ("product_id", "ingredient_id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_sku_key" UNIQUE ("sku");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sale_item_ingredients"
    ADD CONSTRAINT "sale_item_ingredients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");



CREATE UNIQUE INDEX "branches_slug_key" ON "public"."branches" USING "btree" ("slug");



CREATE INDEX "idx_product_ingredients_ingredient" ON "public"."product_ingredients" USING "btree" ("ingredient_id");



CREATE INDEX "idx_product_ingredients_product" ON "public"."product_ingredients" USING "btree" ("product_id");



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."branch_entity_status" FOR EACH ROW EXECUTE FUNCTION "public"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "handle_updated_at" BEFORE UPDATE ON "public"."branch_ingredient_stock" FOR EACH ROW EXECUTE FUNCTION "public"."moddatetime"('updated_at');



CREATE OR REPLACE TRIGGER "on_inventory_update" BEFORE UPDATE ON "public"."inventory" FOR EACH ROW EXECUTE FUNCTION "public"."handle_inventory_update"();



CREATE OR REPLACE TRIGGER "on_product_update" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."handle_product_update"();



CREATE OR REPLACE TRIGGER "on_profile_update" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."handle_profile_update"();



CREATE OR REPLACE TRIGGER "set_timestamp" BEFORE UPDATE ON "public"."ingredients" FOR EACH ROW EXECUTE FUNCTION "public"."trigger_set_timestamp"();



ALTER TABLE ONLY "public"."branch_entity_status"
    ADD CONSTRAINT "branch_entity_status_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."branch_ingredient_stock"
    ADD CONSTRAINT "branch_ingredient_stock_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."branch_ingredient_stock"
    ADD CONSTRAINT "branch_ingredient_stock_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "fk_branch" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "fk_sales_branch" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."inventory"
    ADD CONSTRAINT "inventory_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_ingredients"
    ADD CONSTRAINT "product_ingredients_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."product_ingredients"
    ADD CONSTRAINT "product_ingredients_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_assigned_branch_id_fkey" FOREIGN KEY ("assigned_branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id");



ALTER TABLE ONLY "public"."sale_item_ingredients"
    ADD CONSTRAINT "sale_item_ingredients_ingredient_id_fkey" FOREIGN KEY ("ingredient_id") REFERENCES "public"."ingredients"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."sale_item_ingredients"
    ADD CONSTRAINT "sale_item_ingredients_sale_item_id_fkey" FOREIGN KEY ("sale_item_id") REFERENCES "public"."sale_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sale_items"
    ADD CONSTRAINT "sale_items_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_payment_method_id_fkey" FOREIGN KEY ("payment_method_id") REFERENCES "public"."payment_methods"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



CREATE POLICY "Allow Yöneticiler to read sale_items" ON "public"."sale_items" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role_id" = 1)))));



CREATE POLICY "Allow admin delete access" ON "public"."payment_methods" FOR DELETE USING (true);



CREATE POLICY "Allow admin delete access to categories" ON "public"."categories" FOR DELETE USING (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text"))));



CREATE POLICY "Allow admin full access on ingredients" ON "public"."ingredients" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1)))));



CREATE POLICY "Allow admin full access on sale_item_ingredients" ON "public"."sale_item_ingredients" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1)))));



CREATE POLICY "Allow admin full access on sales" ON "public"."sales" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1)))));



CREATE POLICY "Allow admin full access to branches" ON "public"."branches" USING (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text")))) WITH CHECK (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text"))));



CREATE POLICY "Allow admin insert access" ON "public"."payment_methods" FOR INSERT WITH CHECK (true);



CREATE POLICY "Allow admin insert access to categories" ON "public"."categories" FOR INSERT WITH CHECK (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text"))));



CREATE POLICY "Allow admin update access" ON "public"."payment_methods" FOR UPDATE USING (true);



CREATE POLICY "Allow admin update access to categories" ON "public"."categories" FOR UPDATE USING (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text")))) WITH CHECK (("public"."get_user_role"() = ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE (("roles"."name")::"text" = 'Yönetici'::"text"))));



CREATE POLICY "Allow admin/sales staff to delete sale_items" ON "public"."sale_items" FOR DELETE USING ((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY[1, 3])));



CREATE POLICY "Allow admin/sales staff to update sale_items" ON "public"."sale_items" FOR UPDATE USING ((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY[1, 3]))) WITH CHECK ((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = ANY (ARRAY[1, 3])));



CREATE POLICY "Allow admins full access" ON "public"."products" USING ((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 1)) WITH CHECK ((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 1));



CREATE POLICY "Allow admins to read all profiles" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("public"."get_user_role"() = 1));



CREATE POLICY "Allow cashier admin insert on sale_item_ingredients" ON "public"."sale_item_ingredients" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."sale_items" "si"
     JOIN "public"."sales" "s" ON (("si"."sale_id" = "s"."id")))
     JOIN "public"."profiles" "p" ON (("s"."profile_id" = "p"."id")))
  WHERE (("si"."id" = "sale_item_ingredients"."sale_item_id") AND ("p"."id" = "auth"."uid"()) AND ("p"."role_id" = ANY (ARRAY[1, 3]))))));



CREATE POLICY "Allow cashier admin insert on sale_items" ON "public"."sale_items" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."sales" "s"
     JOIN "public"."profiles" "p" ON (("s"."profile_id" = "p"."id")))
  WHERE (("s"."id" = "sale_items"."sale_id") AND ("p"."id" = "auth"."uid"()) AND ("p"."role_id" = ANY (ARRAY[1, 3]))))));



CREATE POLICY "Allow cashier admin insert on sales" ON "public"."sales" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = ANY (ARRAY[1, 3]))))));



CREATE POLICY "Allow insert/update/delete for admins" ON "public"."product_ingredients" USING ("public"."check_if_admin"());



CREATE POLICY "Allow public read access for active methods" ON "public"."payment_methods" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Allow read access to authenticated users" ON "public"."branches" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read access to authenticated users" ON "public"."categories" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read access to authenticated users" ON "public"."inventory" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read access to authenticated users" ON "public"."product_ingredients" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read access to authenticated users" ON "public"."products" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Allow read access to everyone" ON "public"."roles" FOR SELECT USING (true);



CREATE POLICY "Allow related users read access on sale_item_ingredients" ON "public"."sale_item_ingredients" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."sale_items" "si"
     JOIN "public"."sales" "s" ON (("si"."sale_id" = "s"."id")))
  WHERE (("si"."id" = "sale_item_ingredients"."sale_item_id") AND ("s"."profile_id" = "auth"."uid"())))));



CREATE POLICY "Allow user to insert own profile OR admin to insert any profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((("auth"."uid"() = "id") OR ("role_id" = 1)));



CREATE POLICY "Allow users to read their own profile" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Allow users to update their own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Kasiyerlerin kendi şube satış kalemlerini okumasına izin ve" ON "public"."sale_items" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."sales" "s"
  WHERE (("s"."id" = "sale_items"."sale_id") AND (( SELECT "p"."assigned_branch_id"
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role_id" = 3))) = "s"."branch_id")))));



CREATE POLICY "Kasiyerlerin kendi şube satışlarını okumasına izin ver" ON "public"."sales" FOR SELECT TO "authenticated" USING (((( SELECT "profiles"."role_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = 3) AND (( SELECT "profiles"."assigned_branch_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "auth"."uid"())) = "branch_id")));



CREATE POLICY "Yöneticiler tüm satış kalemlerini okuyabilir" ON "public"."sale_items" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1)))));



CREATE POLICY "Yöneticiler tüm satışları okuyabilir" ON "public"."sales" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role_id" = 1)))));



ALTER TABLE "public"."branches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ingredients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inventory" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payment_methods" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."product_ingredients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sale_item_ingredients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sale_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON FUNCTION "public"."check_if_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_if_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_if_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."decrease_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_decrease" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."decrease_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_decrease" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."decrease_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_decrease" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_sales_last_hour"("target_branch_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_sales_last_hour"("target_branch_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_sales_last_hour"("target_branch_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_inventory_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_inventory_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_inventory_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_product_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_product_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_product_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_profile_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_profile_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_profile_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."increase_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_increase" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."increase_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_increase" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increase_branch_stock"("p_branch_id" "uuid", "p_ingredient_id" "uuid", "p_quantity_to_increase" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."moddatetime"() TO "anon";
GRANT ALL ON FUNCTION "public"."moddatetime"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."moddatetime"() TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_set_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_entity_status" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_entity_status" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_entity_status" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_ingredient_stock" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_ingredient_stock" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branch_ingredient_stock" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branches" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branches" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."branches" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."categories" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."ingredients" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."ingredients" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."ingredients" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."inventory" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."inventory" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."inventory" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payment_methods" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payment_methods" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."payment_methods" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."product_ingredients" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."product_ingredients" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."product_ingredients" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."products" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."products" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."products" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."roles" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."roles" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."roles_id_seq" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_item_ingredients" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_item_ingredients" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_item_ingredients" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_items" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_items" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sale_items" TO "service_role";



GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "anon";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE "public"."sales" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLES TO "service_role";






























RESET ALL;
