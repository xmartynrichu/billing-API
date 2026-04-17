CREATE OR REPLACE FUNCTION public.insert_userdetails(
    username character varying, 
    userid character varying, 
    passwd character varying, 
    dob character varying, 
    mobilenumber character varying, 
    emailid character varying, 
    entryby character varying, 
    ref1 refcursor
)
RETURNS SETOF refcursor
LANGUAGE plpgsql
AS $function$
--Created By: Martin Rijay.X
--Created On: 22-01-2026
--Modified: Added duplicate username check

--select * from insert_userdetails('rrrrrr','wdwd','wdwd','wdwd','wdwd', 'fffff@gmail.com','wefwefwef', 'ref1');fetch all in "ref1";

DECLARE
    v_count INT := 0;
BEGIN
    RAISE NOTICE 'Checking for duplicate username: %', userid;
   
    -- Check if username already exists
    SELECT COUNT(*) INTO v_count
    FROM public.users
    WHERE LOWER(user_id) = LOWER(userid);
    
    IF v_count > 0 THEN
        -- Username already exists
        OPEN ref1 FOR 
        SELECT 'Username already exists. Please choose a different username.' AS result;
        RETURN NEXT ref1;
    ELSE
        -- Username is unique, proceed with insert
        INSERT INTO public.users
        (user_name, user_id, pass_wrd, dateofbirth, mobile_number, email_id, createdby, createdat)
        VALUES(username, userid, passwd, dob, mobilenumber, emailid, entryby, now());
        
        RAISE NOTICE 'User inserted successfully';
        
        OPEN ref1 FOR 
        SELECT 'Insert Successfully' AS result;
        RETURN NEXT ref1;
    END IF;

END;
$function$
;
