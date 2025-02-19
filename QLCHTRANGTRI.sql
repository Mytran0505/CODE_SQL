﻿DROP DATABASE QLCHTRANGTRI
CREATE DATABASE QLCHTRANGTRI

USE QLCHTRANGTRI

CREATE TABLE KHACHHANG
(
	MAKH VARCHAR(5) CONSTRAINT PK_KH PRIMARY KEY,
	TENKH VARCHAR(50),
	DIACHI VARCHAR(50),
	LOAIKH VARCHAR(50)
)

CREATE TABLE MATHANG
(
	MAHANG VARCHAR(5 )CONSTRAINT PK_MH PRIMARY KEY,
	TENMH VARCHAR(50),
	XUATXU VARCHAR(50),
	GIA MONEY
)

CREATE TABLE HOADON
(
	SOHD VARCHAR(5) CONSTRAINT PK_HD PRIMARY KEY,
	NGHD SMALLDATETIME,
	MAKH VARCHAR(5),
	GIAMGIA INT
)

CREATE TABLE CTHD
(
	SOHD VARCHAR(5),
	MAHANG VARCHAR(5),
	SOLUONG INT,
	CONSTRAINT PK_CT PRIMARY KEY (SOHD, MAHANG)
)

ALTER TABLE HOADON
ADD CONSTRAINT Fk_HD_KH FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)

ALTER TABLE CTHD
ADD CONSTRAINT Fk_CT_HD FOREIGN KEY (SOHD) REFERENCES HOADON(SOHD)

ALTER TABLE CTHD
ADD CONSTRAINT Fk_CT FOREIGN KEY (MAHANG) REFERENCES MATHANG(MAHANG)

SET DATEFORMAT DMY

INSERT INTO KHACHHANG VALUES ('KH01', 'Santa Claus', 'North Pole', 'VIP')
INSERT INTO KHACHHANG VALUES ('KH02', 'Rudolph Reindeer', 'Alaska', 'Normal')
INSERT INTO KHACHHANG VALUES ('KH03', 'Elsa', 'Sweden', 'Normal')

INSERT INTO MATHANG VALUES ('MH01', 'Cay thong Noel', 'My', '680000')
INSERT INTO MATHANG VALUES ('MH02', 'Nguoi tuyet bang xop', 'Viet Nam', '500000')
INSERT INTO MATHANG VALUES ('MH03', 'Day den chop sang', 'Trung Quoc', '240000')

INSERT INTO HOADON VALUES ('00001', '22/10/2020', 'KH01', '10')
INSERT INTO HOADON VALUES ('00002', '04/11/2020', 'KH03', '5')
INSERT INTO HOADON VALUES ('00003', '10/11/2020', 'KH02', '2')

INSERT INTO CTHD VALUES ('00001', 'MH01', '1')
INSERT INTO CTHD VALUES ('00001', 'MH02', '2')
INSERT INTO CTHD VALUES ('00003', 'MH03', '5')

--3. Hiện thực ràng buộc toàn vẹn sau: Tất cả các mặt hàng xuất xứ từ Mỹ đều có giá lớn hơn 
--500.000 (1đ).
ALTER TABLE MATHANG
ADD CONSTRAINT CK_MH CHECK( XUATXU!='My' OR (XUATXU='My' AND GIA>500000))

INSERT INTO MATHANG VALUES ('MH04', 'Day den chop sang', 'Viet nam', '240000')
UPDATE MATHANG
SET XUATXU='TRUNG QUOC'
WHERE MAHANG='MH04'
DELETE FROM MATHANG WHERE MAHANG='MH04'
--4. Hiện thực ràng buộc toàn vẹn sau: Hóa đơn của những khách hàng thuộc loại VIP luôn được 
--giảm giá lớn hơn hoặc bằng 10 phần trăm. (2đ).

--TRIGGER ON KHACHHANG
CREATE TRIGGER TRIGGER_UPDATE_KH ON KHACHHANG
FOR UPDATE
AS
BEGIN
	IF EXISTS ( SELECT *
	            FROM INSERTED KH, HOADON HD
	            WHERE HD.MAKH=KH.MAKH AND KH.LOAIKH ='VIP' AND GIAMGIA <10)
		BEGIN
			PRINT 'ERROR!'
			ROLLBACK TRAN
		END
	ELSE
		PRINT 'THANH CONG'
END

UPDATE KHACHHANG
SET LOAIKH='Normal'
WHERE MAKH='KH02'
--TRIGGER ON HOADON
DROP TRIGGER TRIGGER_INSERT_UPDATE_HD

CREATE TRIGGER TRIGGER_INSERT_UPDATE_HD ON HOADON
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @LOAIKH VARCHAR(50), @GIAMGIA INT

	SELECT @LOAIKH=LOAIKH, @GIAMGIA=GIAMGIA
	FROM INSERTED HD, KHACHHANG KH
	WHERE HD.MAKH=KH.MAKH

	IF(@LOAIKH='VIP')
		IF(@GIAMGIA < 10)
			BEGIN
				PRINT 'ERROR!'
				ROLLBACK TRAN
			END
		ELSE
			PRINT 'THANH CONG'
END

INSERT INTO HOADON VALUES ('00004', '10/11/2020', 'KH01', '11')
UPDATE HOADON
SET MAKH='KH02'
WHERE SOHD='00002'
DELETE FROM HOADON WHERE SOHD='00004'
--5. Tìm tất cả các hóa đơn có ngày lập hóa đơn trong tháng 11 năm 2020, sắp xếp kết quả tăng 
--dần theo phần trăm giảm giá (1đ).
SELECT SOHD
FROM HOADON
WHERE MONTH(NGHD)=11 AND YEAR(NGHD)=2020
ORDER BY GIAMGIA ASC
--6. Tìm mặt hàng có số lượng mua nhiều nhất trong năm 2020 (1đ).
SELECT MH.MAHANG, TENMH
FROM MATHANG MH, CTHD CT, HOADON HD
WHERE MH.MAHANG=CT.MAHANG AND CT.SOHD=HD.SOHD AND YEAR(NGHD)=2020
GROUP BY MH.MAHANG, TENMH
HAVING SUM(SOLUONG) >= ALL( SELECT SUM(SOLUONG)
							FROM CTHD CT, HOADON HD
							WHERE CT.SOHD=HD.SOHD AND YEAR(NGHD)=2020
							GROUP BY MAHANG)

SELECT TOP 1 WITH TIES MH.MAHANG, TENMH
FROM MATHANG MH, CTHD CT, HOADON HD
WHERE MH.MAHANG=CT.MAHANG AND CT.SOHD=HD.SOHD AND YEAR(NGHD)=2020
GROUP BY MH.MAHANG, TENMH
ORDER BY SUM(SOLUONG) DESC
--7. Tìm mặt hàng chỉ có khách VIP (LOAIKH là VIP) mua, khách thường (LOAIKH là Normal) 
--không mua. (1đ).
SELECT MH.MAHANG, TENMH
FROM MATHANG MH, CTHD CT
WHERE MH.MAHANG=CT.MAHANG 
EXCEPT
SELECT MH.MAHANG, TENMH
FROM MATHANG MH, CTHD CT, HOADON HD, KHACHHANG KH
WHERE MH.MAHANG=CT.MAHANG AND CT.SOHD=HD.SOHD AND HD.MAKH= KH.MAKH
      AND LOAIKH!='VIP'
--8. Tìm khách hàng đã từng mua tất cả các mặt hàng xuất xứ Việt Nam trong năm 2020 (1đ).
SELECT MAKH, TENKH
FROM KHACHHANG KH
WHERE NOT EXISTS( SELECT *
				  FROM MATHANG MH, CTHD CT
				  WHERE MH.MAHANG=CT.MAHANG AND XUATXU='Viet Nam'
				        AND NOT EXISTS( SELECT *
						                FROM HOADON HD
										WHERE HD.SOHD=CT.SOHD AND HD.MAKH=KH.MAKH
										      AND YEAR(NGHD)=2020))
SELECT MAKH, TENKH
FROM KHACHHANG KH
WHERE NOT EXISTS( SELECT *
				  FROM MATHANG MH
				  WHERE XUATXU='Viet Nam'
				        AND NOT EXISTS( SELECT *
						                FROM HOADON HD, CTHD CT
										WHERE MH.MAHANG=CT.MAHANG AND 
										      HD.SOHD=CT.SOHD AND HD.MAKH=KH.MAKH
											  AND YEAR(NGHD)=2020))