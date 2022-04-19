server {
    listen 80;

    server_name ${domain} www.${domain};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot/${domain};
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen       443 ssl;
    server_name  ${domain} www.${domain};

    ssl_certificate /etc/nginx/ssl/dummy/${domain}/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/dummy/${domain}/privkey.pem;

    include /etc/nginx/options-ssl-nginx.conf;

    ssl_dhparam /etc/nginx/ssl/ssl-dhparams.pem;

    include /etc/nginx/hsts.conf;

    location ^~ /orthanc {
        proxy_set_header        Host $host:$server_port;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        proxy_pass              http://orthanc:8042/;
        proxy_read_timeout      90;

        proxy_redirect          http://orthanc:8042 https://$server_name/orthanc/;
    }

    # account for Orthanc post login redirect
    location ^~ /app/ {
        return 301 https://$server_name/orthanc$request_uri;
    }

    # Send OHIF Viewer requests requests to the OHIF Viewer server.
    location / {
        proxy_set_header        Host $host:$server_port;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;

        proxy_pass              http://viewer:3000/;
        proxy_read_timeout      90;

        proxy_redirect          http://viewer:3000 https://$server_name;
    }
}
