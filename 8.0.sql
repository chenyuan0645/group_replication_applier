use sys;
drop FUNCTION if exists IFZERO;
drop FUNCTION if exists LOCATE2;
drop FUNCTION if exists GTID_NORMALIZE ;
drop FUNCTION if exists GTID_COUNT;
drop FUNCTION if exists gr_applier_queue_length ;
drop FUNCTION if exists gr_member_in_primary_partition;

DELIMITER ;;
CREATE FUNCTION `IFZERO`(a INT, b INT) RETURNS int(11)
    DETERMINISTIC
RETURN IF(a = 0, b, a) ;;
DELIMITER ;

DELIMITER ;;
CREATE FUNCTION `LOCATE2`(needle TEXT(10000), haystack TEXT(10000), offset INT) RETURNS int(11)
    DETERMINISTIC
RETURN IFZERO(LOCATE(needle, haystack, offset), LENGTH(haystack) + 1) ;;
DELIMITER ;

DELIMITER ;;
CREATE FUNCTION `GTID_NORMALIZE`(g TEXT(10000)) RETURNS text
    DETERMINISTIC
RETURN GTID_SUBTRACT(g, '') ;;
DELIMITER ;

DELIMITER ;;
CREATE FUNCTION `GTID_COUNT`(gtid_set TEXT(10000)) RETURNS int(11)
    DETERMINISTIC
BEGIN
  DECLARE result BIGINT DEFAULT 0;
  DECLARE colon_pos INT;
  DECLARE next_dash_pos INT;
  DECLARE next_colon_pos INT;
  DECLARE next_comma_pos INT;
  SET gtid_set = GTID_NORMALIZE(gtid_set);
  SET colon_pos = LOCATE2(':', gtid_set, 1);
  WHILE colon_pos != LENGTH(gtid_set) + 1 DO
     SET next_dash_pos = LOCATE2('-', gtid_set, colon_pos + 1);
     SET next_colon_pos = LOCATE2(':', gtid_set, colon_pos + 1);
     SET next_comma_pos = LOCATE2(',', gtid_set, colon_pos + 1);
     IF next_dash_pos < next_colon_pos AND next_dash_pos < next_comma_pos THEN
       SET result = result +
         SUBSTR(gtid_set, next_dash_pos + 1,
                LEAST(next_colon_pos, next_comma_pos) - (next_dash_pos + 1)) -
         SUBSTR(gtid_set, colon_pos + 1, next_dash_pos - (colon_pos + 1)) + 1;
     ELSE
       SET result = result + 1;
     END IF;
     SET colon_pos = next_colon_pos;
  END WHILE;
  RETURN result;
END ;;
DELIMITER ;

DELIMITER ;;
CREATE FUNCTION `gr_applier_queue_length`() RETURNS int(11)
    DETERMINISTIC
BEGIN
  RETURN (SELECT sys.gtid_count(GTID_SUBTRACT((
SELECT Received_transaction_set
FROM performance_schema.replication_connection_status
WHERE Channel_name = 'group_replication_applier'
), (
SELECT @@global.GTID_EXECUTED
))));
END ;;
DELIMITER ;

DELIMITER ;;
CREATE FUNCTION `gr_member_in_primary_partition`() RETURNS varchar(3)
    DETERMINISTIC
BEGIN
  RETURN (SELECT IF(MEMBER_STATE = 'ONLINE'
AND (
SELECT COUNT(*)
FROM performance_schema.replication_group_members
WHERE MEMBER_STATE != 'ONLINE'
) >= (
SELECT COUNT(*)
FROM performance_schema.replication_group_members
) / 2 = 0, 'YES', 'NO')
FROM performance_schema.replication_group_members
JOIN performance_schema.replication_group_member_stats USING (member_id)
WHERE member_id = (
SELECT VARIABLE_VALUE
FROM performance_schema.global_variables
WHERE VARIABLE_NAME = 'server_uuid'
));
END ;;
DELIMITER ;

drop VIEW if exists v_mgr_monitor;
CREATE VIEW v_mgr_monitor AS SELECT pfsrgm.MEMBER_ID AS MEMBER_ID, pfsrgm.MEMBER_ROLE AS MEMBER_ROLE,pfsrgm.MEMBER_STATE AS MEMBER_STATE ,sys.gr_member_in_primary_partition() AS viable_candidate , if(( SELECT ( SELECT GROUP_CONCAT(performance_schema.global_variables.VARIABLE_VALUE SEPARATOR ',') FROM performance_schema.global_variables WHERE performance_schema.global_variables.VARIABLE_NAME IN ('read_only', 'super_read_only')) <> 'OFF,OFF' ), 'YES', 'NO') AS read_only , sys.gr_applier_queue_length() AS transactions_behind, pfsrgms.COUNT_TRANSACTIONS_IN_QUEUE AS transactions_to_cert FROM performance_schema.replication_group_member_stats pfsrgms JOIN performance_schema.replication_group_members pfsrgm ON pfsrgms.MEMBER_ID = pfsrgm.MEMBER_ID WHERE pfsrgms.MEMBER_ID = ( SELECT performance_schema.global_variables.VARIABLE_VALUE FROM performance_schema.global_variables WHERE performance_schema.global_variables.VARIABLE_NAME = 'server_uuid') ;

-- select t1.MEMBER_ID,t1.MEMBER_ROLE,t1.MEMBER_STATE,ifnull(t2.viable_candidate,sys.gr_member_in_primary_partition()) viable_candidate,t2.read_only AS read_only, t2.transactions_behind AS transactions_behind, t2.transactions_to_cert AS transactions_to_cert from (SELECT MEMBER_ROLE, MEMBER_STATE, MEMBER_ID FROM performance_schema.replication_group_members) t1 left join sys.v_mgr_monitor t2 on t1.MEMBER_ID = t2.MEMBER_ID; 
