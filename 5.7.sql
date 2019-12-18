USE sys;

DELIMITER $$

drop FUNCTION if exists IFZERO$$
CREATE FUNCTION IFZERO(a INT, b INT)
RETURNS INT
DETERMINISTIC
RETURN IF(a = 0, b, a)$$

drop FUNCTION if exists LOCATE2$$
CREATE FUNCTION LOCATE2(needle TEXT(10000), haystack TEXT(10000), offset INT)
RETURNS INT
DETERMINISTIC
RETURN IFZERO(LOCATE(needle, haystack, offset), LENGTH(haystack) + 1)$$



drop FUNCTION if exists GTID_NORMALIZE$$
CREATE FUNCTION GTID_NORMALIZE(g TEXT(10000))
RETURNS TEXT(10000)
DETERMINISTIC
RETURN GTID_SUBTRACT(g, '')$$


drop FUNCTION if exists GTID_COUNT$$
CREATE FUNCTION GTID_COUNT(gtid_set TEXT(10000))
RETURNS INT
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
END$$


drop FUNCTION if exists gr_applier_queue_length$$
CREATE FUNCTION gr_applier_queue_length()
RETURNS INT
DETERMINISTIC
BEGIN
  RETURN (SELECT sys.gtid_count( GTID_SUBTRACT( (SELECT
Received_transaction_set FROM performance_schema.replication_connection_status
WHERE Channel_name = 'group_replication_applier' ), (SELECT
@@global.GTID_EXECUTED) )));
END$$


drop FUNCTION if exists gr_member_in_primary_partition$$
CREATE FUNCTION gr_member_in_primary_partition()
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
  RETURN (SELECT IF( MEMBER_STATE='ONLINE' AND ((SELECT COUNT(*) FROM
performance_schema.replication_group_members WHERE MEMBER_STATE != 'ONLINE') >=
((SELECT COUNT(*) FROM performance_schema.replication_group_members)/2) = 0),
'YES', 'NO' ) FROM performance_schema.replication_group_members JOIN
performance_schema.replication_group_member_stats USING(member_id) where member_id = (select VARIABLE_VALUE from performance_schema.global_variables where VARIABLE_NAME = 'server_uuid'));
END$$

DELIMITER $$
drop VIEW if exists v_mgr_monitor $$
CREATE VIEW v_mgr_monitor  AS SELECT pfsrgm.MEMBER_ID,if((select if(VARIABLE_VALUE='',(select if(VARIABLE_VALUE='','PRIMARY',VARIABLE_VALUE) from performance_schema.global_variables where VARIABLE_NAME = 'server_uuid'),VARIABLE_VALUE) from performance_schema.global_status where VARIABLE_NAME = 'group_replication_primary_member')=(select if(VARIABLE_VALUE='','PRIMARY',VARIABLE_VALUE) from performance_schema.global_variables where VARIABLE_NAME = 'server_uuid'),'PRIMARY','SECONDARY') MEMBER_ROLE,pfsrgm.MEMBER_STATE,sys.gr_member_in_primary_partition() AS viable_candidate, IF((
		SELECT (
				SELECT GROUP_CONCAT(variable_value)
				FROM performance_schema.global_variables
				WHERE variable_name IN ('read_only', 'super_read_only')
			) != 'OFF,OFF'
	), 'YES', 'NO') AS read_only
	, sys.gr_applier_queue_length() AS transactions_behind, Count_Transactions_in_queue AS 'transactions_to_cert'
FROM performance_schema.replication_group_member_stats pfsrgms join performance_schema.replication_group_members pfsrgm on pfsrgms.MEMBER_ID = pfsrgm.MEMBER_ID
WHERE pfsrgms.member_id = (
	SELECT VARIABLE_VALUE
	FROM performance_schema.global_variables
	WHERE VARIABLE_NAME = 'server_uuid'
)$$

DELIMITER ;




-- select t1.MEMBER_ID,if(t1.MEMBER_ID = (select if(VARIABLE_VALUE='','PRIMARY',VARIABLE_VALUE) from performance_schema.global_status where VARIABLE_NAME = 'group_replication_primary_member') or (select if(VARIABLE_VALUE='','PRIMARY',VARIABLE_VALUE) from performance_schema.global_status where VARIABLE_NAME = 'group_replication_primary_member') = 'PRIMARY' ,'PRIMARY','SECONDARY') MEMBER_ROLE,t1.MEMBER_STATE,ifnull(t2.viable_candidate,sys.gr_member_in_primary_partition()) viable_candidate,t2.read_only AS read_only, t2.transactions_behind AS transactions_behind, t2.transactions_to_cert AS transactions_to_cert from (SELECT  MEMBER_STATE, MEMBER_ID FROM performance_schema.replication_group_members) t1 left join sys.v_mgr_monitor t2 on t1.MEMBER_ID = t2.MEMBER_ID;

