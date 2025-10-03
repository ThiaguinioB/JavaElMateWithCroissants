-- 🗄️ Script de Inicialización de Bases de Datos para Horusec Platform
--
-- Este script SQL crea todas las bases de datos necesarias para que
-- la plataforma completa de Horusec funcione correctamente.
--
-- Bases de datos creadas:
-- - horusec_api: Almacena datos de la API principal (proyectos, análisis, etc.)
-- - horusec_auth: Gestiona usuarios, autenticación y autorización
-- - horusec_core: Almacena configuraciones del motor de análisis
-- - horusec_analytic: Datos para reportes y métricas analíticas
-- - horusec_messages: Cola de mensajes y notificaciones
--
-- Uso: Este script se ejecuta automáticamente cuando se inicia PostgreSQL
--      por primera vez, o puede ejecutarse manualmente con:
--      psql -U horusec -d postgres -f init-databases.sql
--
-- Nota: En la configuración actual de docker-compose, este script NO se usa
--       automáticamente ya que Horusec maneja la creación de esquemas internamente

-- 🔧 Crear base de datos para la API principal
CREATE DATABASE horusec_api;

-- 🔐 Crear base de datos para autenticación y autorización  
CREATE DATABASE horusec_auth;

-- ⚙️ Crear base de datos para el motor de análisis
CREATE DATABASE horusec_core;

-- 📊 Crear base de datos para analíticas y reportes
CREATE DATABASE horusec_analytic;

-- 📨 Crear base de datos para sistema de mensajería
CREATE DATABASE horusec_messages;
