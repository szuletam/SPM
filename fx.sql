DELIMITER $$


DROP FUNCTION IF EXISTS `fx_weeklydays`$$

CREATE FUNCTION `fx_weeklydays`(d_start DATE, d_end DATE) RETURNS int(11)
    DETERMINISTIC
BEGIN
 DECLARE days, holidays, done, addfisrtday INT;
  SET days := DATEDIFF(d_end,d_start);
  SET holidays := 0;
  SET done := 0;
  SET addfisrtday := 0;
  SET days := days + 1;
  IF (d_start IS NULL) OR (d_end IS NULL) THEN
    RETURN 1;
  END IF;
  IF (d_start > d_end) THEN
    RETURN 1;
  END IF;
  WHILE done = 0 DO
    IF fx_holiday(d_start) = 1 THEN
        SET holidays := holidays + 1;
    END IF;
    SET d_start := d_start + INTERVAL 1 DAY ;
    IF d_start > d_end THEN
        SET done := 1;
    END IF;
  END WHILE;
  SET days := days - holidays ;
  IF days <= 0 THEN
    SET days := 1;
  END IF;
  RETURN days;
END$$

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS `fx_holiday`$$

CREATE FUNCTION `fx_holiday`(in_date DATE) RETURNS int(11)
    DETERMINISTIC
BEGIN
DECLARE r INT;
  SELECT IFNULL((SELECT IF(WEEKDAY(in_date)=5,1,IF(WEEKDAY(in_date)=6,1,0)) FROM DUAL) OR (SELECT 1 FROM holidays WHERE date = in_date),0) INTO r;
RETURN r;
END$$

DELIMITER $$

DROP FUNCTION IF EXISTS `fx_weeklydays_negative`$$

CREATE FUNCTION `fx_weeklydays_negative`(d_start DATE, d_end DATE) RETURNS int(11)
    DETERMINISTIC
BEGIN
 DECLARE days, holidays, done, addfisrtday INT;
 DECLARE tmp_date DATE;
  SET days := DATEDIFF(d_end,d_start);
  SET holidays := 0;
  SET done := 0;
  SET addfisrtday := 0;
  IF days > 0 THEN
	SET days := days + 1;
  ELSE
	IF days = 0 THEN
		SET days := days + 1;
	ELSE
		SET days := days - 1;
	END IF;
  END IF;  
  IF (d_start IS NULL) OR (d_end IS NULL) THEN
    RETURN 1;
  END IF;
  IF (d_start > d_end) THEN
    SET tmp_date := d_start;
    SET d_start := d_end;
    SET d_end := tmp_date;
  END IF;
  WHILE done = 0 DO
    IF fx_holiday(d_start) = 1 THEN
        SET holidays := holidays + 1;
    END IF;
    SET d_start := d_start + INTERVAL 1 DAY ;
    IF d_start > d_end THEN
        SET done := 1;
    END IF;
  END WHILE;
  IF days > 0 THEN
	SET days := days - holidays;
  ELSE
	IF days = 0 THEN
		SET days := 0;
	ELSE
		SET days := days + holidays;
	END IF;
  END IF;
  /*IF days <= 0 THEN
    SET days := 1;
  END IF;*/
  RETURN days;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS updatespm;

DELIMITER //
CREATE PROCEDURE updatespm()
  BEGIN

    SET @inc := 0;
    UPDATE issues
    SET spmid = CONCAT('T',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 2
          AND YEAR(created_on) = '2016'
    ORDER BY created_on;

    SET @inc := 0;
    UPDATE issues
    SET spmid = CONCAT('T',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 2
          AND YEAR(created_on) = '2017'
    ORDER BY created_on;

    SET @inc :=0;
    UPDATE issues
    SET spmid = CONCAT('A',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 4
          AND YEAR(created_on) = '2016'
    ORDER BY created_on;

    SET @inc :=0;
    UPDATE issues
    SET spmid = CONCAT('A',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 4
          AND YEAR(created_on) = '2017'
    ORDER BY created_on;

    SET @inc := 0;
    UPDATE issues
    SET spmid = CONCAT('D',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 5
          AND YEAR(created_on) = '2016'
    ORDER BY created_on;

    SET @inc := 0;
    UPDATE issues
    SET spmid = CONCAT('D',@inc := @inc + 1, '-',YEAR(created_on))
    WHERE tracker_id = 5
          AND YEAR(created_on) = '2017'
    ORDER BY created_on;

  END//

DELIMITER ;

CALL updatespm();


DROP TRIGGER IF EXISTS get_spmid;

DELIMITER //

CREATE TRIGGER get_spmid BEFORE INSERT ON issues
FOR EACH ROW
  BEGIN
    DECLARE last_spmid INTEGER DEFAULT NULL;
    DECLARE year_issue VARCHAR(4) DEFAULT NULL;
    DECLARE abrv_tracker CHAR(1) DEFAULT NULL;


    IF NEW.tracker_id = 4 THEN
      SET abrv_tracker = 'A';
    ELSEIF NEW.tracker_id = 5 THEN
      SET abrv_tracker = 'D';
    ELSE
      SET abrv_tracker = 'T';
    END IF;

    SELECT CONVERT(SUBSTRING(spmid, 2, LENGTH(spmid)),UNSIGNED INTEGER), YEAR(created_on) INTO last_spmid, year_issue
    FROM issues
    WHERE tracker_id = NEW.tracker_id
          AND YEAR(created_on) = YEAR(NEW.created_on)
    ORDER BY created_on DESC
    LIMIT 1;

    IF last_spmid IS NULL THEN
      SET last_spmid = 0;
    END IF;

    IF year_issue IS NULL THEN
      SET year_issue = YEAR(NEW.created_on);
    END IF;


    SET NEW.spmid = CONCAT(abrv_tracker, last_spmid + 1, '-', year_issue);
  END//

DELIMITER ;

