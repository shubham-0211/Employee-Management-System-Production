-- =====================================================
-- Employee Management System
-- Initial Admin Account Seed
-- =====================================================

INSERT INTO users (
    employee_id,
    username,
    email,
    password_hash,
    role,
    status,
    must_change_password
)
SELECT
    NULL,
    'sysadmin',
    'shubham.ghongade@admin.com',
    '$2a$10$bts3kDPQi3yVs00puAVLPeUAObEFs7R51JpgTAukek3gjLxSGYK1i',
    'ADMIN',
    'ACTIVE',
    FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM users
    WHERE role = 'ADMIN'
       OR username = 'sysadmin'
       OR email = 'shubham.ghongade@admin.com'
);
