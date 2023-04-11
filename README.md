# nginx-container
自用的nginx容器

### ngx_headers_more

https://github.com/openresty/headers-more-nginx-module.git

### nginx_http_upstream_check_module - support upstream health check with Nginx

https://github.com/yaoweibin/nginx_upstream_check_module.git

~~https://github.com/alibaba/tengine/tree/master/modules/ngx_http_upstream_check_module~~

### Nginx virtual host traffic status module

https://github.com/vozlt/nginx-module-vts.git


### nginx-sticky-module-ng

https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng.git

https://github.com/Refinitiv/nginx-sticky-module-ng

https://github.com/ishushkin/nginx-sticky-module-ng/archive/refs/heads/master.zip

### Just! a Hide Server Signature of Nginx Web Server

https://github.com/torden/ngx_hidden_signature_patch


~~### ModSecurity-nginx~~

~~https://github.com/SpiderLabs/ModSecurity-nginx~~

~~### ngx_waf~~

~~https://github.com/ADD-SP/ngx_waf~~

### naxsi

~~https://github.com/nbs-system/naxsi/~~

https://github.com/wargio/naxsi



设置代理
```
export http_proxy=http://localhost:7890
export https_proxy=http://localhost:7890
```

取消代理
```
unset https_proxy
unset http_proxy
```

删除旧镜像
```
podman rmi $(podman images -qa custom-nginx) -f
```

build镜像
```
buildah bud -t custom-nginx:1.22.1 .
buildah bud -t custom-nginx:1.22.1-$(date +%Y%m%d%H%M%S) .
```

测试镜像
```


podman run -p 80:80 -p 443:443 --rm -it localhost/custom-nginx:1.22.1 /bin/bash
podman run -p 80:80 -p 443:443 --rm localhost/custom-nginx:1.22.1

```

保存/加载镜像
```

podman save -o custom-nginx.1.22.1.tar localhost/custom-nginx:1.22.1
podman load -i custom-nginx.1.22.1.tar

```



