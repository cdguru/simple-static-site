# Usar imagen nginx ligera basada en Alpine
FROM nginx:stable-alpine

# Copiar archivos del sitio estático al directorio raíz de nginx
COPY index.html /usr/share/nginx/html/
COPY styles.css /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/

# Exponer puerto 80
EXPOSE 80

# nginx se inicia automáticamente como proceso principal
