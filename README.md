# atoms-demo-gitops

[Atoms Demo](https://github.com/haobinfei/Atoms-Demo) 的 GitOps 仓库：
Helm chart + Argo CD Application，子域 `atoms.ss-vip.cn`，cert-manager TLS。
与应用仓库平级，不改动既有生产 gitops 仓库。

## 拓扑

```
浏览器 ──HTTPS──> ingress-nginx ──> web(nginx: SPA + 反代 /api /app /pay)
                                      └──> server(Atoms Demo API, :4173)
```

与本地开发、docker compose 的拓扑一致：web 伺服前端构建产物并把后端
路径反代给 server，SSE 事件流全程不缓冲。

## 自动拉起（push 后自动部署）

```
Atoms-Demo 仓库发版
   → self-hosted runner（ARC）构建 server/web 镜像并推送阿里云 ACR（ss-vip 命名空间）
   → 发布流程回写本仓库 charts/atoms-demo/values.yaml 的 images.*.tag
   → Argo CD 检测到 git 变化（syncPolicy.automated + selfHeal）
   → 自动 sync，新镜像滚动上线
```

`argocd/application.yaml` 即 Application 模板：

```bash
kubectl apply -f argocd/application.yaml   # 在已装 Argo CD 的集群里
```

## 前置条件

- Argo CD（namespace `argocd`）
- ingress-nginx + `letsencrypt-prod` ClusterIssuer（cert-manager）
- 可拉取 `registry.cn-hangzhou.aliyuncs.com/ss-vip` 镜像（与 AuthSphere 同一
  ACR 命名空间，集群节点已配置拉取权限，无需 imagePullSecrets）

## 本地验证（无集群）

```bash
helm lint charts/atoms-demo
helm template atoms-demo charts/atoms-demo | less

# 模拟「push 新镜像后自动更新」：改 tag 重新渲染，deployment 镜像随之变化
helm template atoms-demo charts/atoms-demo \
  --set images.server.tag=20261011-2 --set images.web.tag=20261011-2 \
  | grep 'image:'
```

最后一次渲染校验（见 Atoms-Demo 票 #12 收尾记录）：tag 从 0.1.0 改为
20261011-2 后，server/web 两个 Deployment 的 image 字段同步变化，
Argo CD 的 automated sync 会以同样方式消化这次 git 变更。
