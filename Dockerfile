# Utiliza la imagen oficial de OpenJDK 21 como base
FROM eclipse-temurin:21-jdk

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /C:\Users\Usuario\OneDrive\Escritorio\Trabajo\Development\Java\JavaElMateWithCroissants\src
# Copia el archivo JAR de tu juego al contenedor
# Reemplaza 'tu-juego.jar' por el nombre real de tu archivo JAR
COPY * .

# Expone el puerto si tu juego lo necesita (por ejemplo, 8080)
# EXPOSE 8080

# Comando para ejecutar el juego
CMD ["java", "-jar", "build/libs/JavaElMateWithCroissants.jar"]