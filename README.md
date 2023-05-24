# nginx-container
自用的nginx容器

### ngx_headers_more
https://github.com/openresty/headers-more-nginx-module.git

### nginx_http_upstream_check_module 

### Nginx virtual host traffic status module

### nginx-sticky-module-ng

### Just! a Hide Server Signature of Nginx Web Server

https://github.com/torden/ngx_hidden_signature_patch

### ModSecurity-nginx

https://github.com/SpiderLabs/ModSecurity-nginx



设置代理
```
export http_proxy=http://192.168.31.123:7890
export https_proxy=http://192.168.31.123:7890
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
buildah bud -t tmp_1 tmp_1/
buildah bud -t tmp_2 tmp_2/
buildah bud -t custom-nginx:1.22.1 .
buildah bud -t custom-nginx:1.22.1-$(date +%Y%m%d%H%M%S) .
```

测试镜像
```


podman run --network=host --rm -it localhost/custom-nginx:1.22.1 /bin/bash
podman run --network=host --rm localhost/custom-nginx:1.22.1


```

保存/加载镜像
```

podman save -o custom-nginx.1.22.1.tar localhost/custom-nginx:1.22.1
podman load -i custom-nginx.1.22.1.tar

```


