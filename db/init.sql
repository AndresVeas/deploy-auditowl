-- ========================================================
-- OwlAudit - Script de Inicialización y Semillas de Base de Datos
-- ========================================================

CREATE DATABASE IF NOT EXISTS owl_auditv1;
USE owl_auditv1;

-- Creación de la tabla de usuarios requerida por OwlAudit
CREATE TABLE IF NOT EXISTS usuarios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL
);

-- Carga inicial de usuarios semilla para pruebas de autenticación
INSERT INTO usuarios (nombre, correo, contrasena, rol)
VALUES 
    ('Profesor Titular', 'docente@epn.edu.ec', 'docente123', 'DOCENTE'),
    ('Estudiante Uno', 'estudiante1@epn.edu.ec', 'estudiante123', 'ESTUDIANTE'),
    ('Estudiante Dos', 'estudiante2@epn.edu.ec', 'estudiante456', 'ESTUDIANTE')
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre);
