CREATE TRIGGER trg_CheckClassroomCapacityAndClassLimit
ON enrollment
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for the number of registered classes in the building
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN class c ON i.classid = c.classid
        INNER JOIN classroom cl ON c.classroomid = cl.classroomid
        INNER JOIN enrollment e ON c.classid = e.classid
        WHERE c.semester = i.semester
          AND c.status = 'Active'
        GROUP BY cl.building, c.semester
        HAVING COUNT(DISTINCT e.classid) > 50
    )
    BEGIN
        -- Log to audittrail
        INSERT INTO audittrail (departmentid, classid)
        SELECT d.departmentid, i.classid
        FROM inserted i
        INNER JOIN class c ON i.classid = c.classid
        INNER JOIN department d ON c.departmentid = d.departmentid
        WHERE NOT EXISTS (SELECT 1
                          FROM audittrail
                          WHERE classid = i.classid);

        -- Stop execution if rule violated
        RAISERROR ('More than 50 classes registered in the building for the semester.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Check if class enrollment exceeds classroom capacity
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN class c ON i.classid = c.classid
        INNER JOIN classroom cl ON c.classroomid = cl.classroomid
        GROUP BY c.classid, cl.capacity
        HAVING COUNT(*) > cl.capacity
    )
    BEGIN
        -- Log to audittrail
        INSERT INTO audittrail (departmentid, classid)
        SELECT d.departmentid, i.classid
        FROM inserted i
        INNER JOIN class c ON i.classid = c.classid
        INNER JOIN department d ON c.departmentid = d.departmentid
        WHERE NOT EXISTS (SELECT 1
                          FROM audittrail
                          WHERE classid = i.classid);

        -- Stop execution if rule violated
        RAISERROR ('Class enrollment exceeds classroom capacity.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END

DROP TRIGGER trg_CheckClassroomCapacityAndClassLimit;

