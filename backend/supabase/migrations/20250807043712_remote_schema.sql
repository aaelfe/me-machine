alter table "public"."conversations" add column "title" text;

alter table "public"."profiles" alter column "id" drop default;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_profile_for_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    INSERT INTO public.profiles (id, email, created_at)
    VALUES (NEW.id, NEW.email, NEW.created_at);
    
    RETURN NEW;
END;
$function$
;


