locals {
  # render helm chart values since direct passing of values does not work in all cases
  nginx_values = <<EOT
controller:
  name: controller
  image:
    pullPolicy: IfNotPresent
    # www-data -> uid 101
    runAsUser: 101
    allowPrivilegeEscalation: true

  # Use an existing PSP instead of creating one
  existingPsp: ""

  # Configures the controller container name
  containerName: controller

  # Configures the ports the nginx-controller listens on
  containerPort:
    http: 80
    https: 443

  # Will add custom configuration options to Nginx https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/
  config:
    data:
      enable-opentracing: "${var.opentracing_config != null}"
%{ if var.opentracing_config != null ~}
      jaeger-collector-host: ${var.opentracing_config.jaeger_agent_host}
%{ if var.opentracing_config.jaeger_agent_port != 0 ~}
      jaeger-collector-port: ${var.opentracing_config.jaeger_agent_port}
%{ endif ~}
      opentracing-trust-incoming-span: "true"
%{ endif ~}

  ## Annotations to be added to the controller config configuration configmap
  ##
  configAnnotations: {}

  # Will add custom headers before sending traffic to backends according to https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples/customization/custom-headers
  proxySetHeaders: {}

  # Will add custom headers before sending response traffic to the client according to: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#add-headers
  addHeaders: {}

  # Optionally customize the pod dnsConfig.
  dnsConfig: {}

  # Optionally customize the pod hostname.
  hostname: {}

  # Optionally change this to ClusterFirstWithHostNet in case you have 'hostNetwork: true'.
  # By default, while using host network, name resolution uses the host's DNS. If you wish nginx-controller
  # to keep resolving names inside the k8s network, use ClusterFirstWithHostNet.
  dnsPolicy: ClusterFirst

  # Bare-metal considerations via the host network https://kubernetes.github.io/ingress-nginx/deploy/baremetal/#via-the-host-network
  # Ingress status was blank because there is no Service exposing the NGINX Ingress controller in a configuration using the host network, the default --publish-service flag used in standard cloud setups does not apply
  reportNodeInternalIp: false

  # Process Ingress objects without ingressClass annotation/ingressClassName field
  # Overrides value for --watch-ingress-without-class flag of the controller binary
  # Defaults to false
  watchIngressWithoutClass: false

  # Process IngressClass per name (additionally as per spec.controller)
  ingressClassByName: false

  # This configuration defines if Ingress Controller should allow users to set
  # their own *-snippet annotations, otherwise this is forbidden / dropped
  # when users add those annotations.
  # Global snippets in ConfigMap are still respected
  allowSnippetAnnotations: true

  # Required for use with CNI based kubernetes installations (such as ones set up by kubeadm),
  # since CNI and hostport don't mix yet. Can be deprecated once https://github.com/kubernetes/kubernetes/issues/23920
  # is merged
  hostNetwork: false

  ## Use host ports 80 and 443
  ## Disabled by default
  ##
  hostPort:
    enabled: false
    ports:
      http: 80
      https: 443

  ## Election ID to use for status update
  ##
  electionID: ingress-controller-leader

  # This section refers to the creation of the IngressClass resource
  # IngressClass resources are supported since k8s >= 1.18 and required since k8s >= 1.19
  ingressClassResource:
    name: nginx
    enabled: true
    default: true
    controllerValue: "k8s.io/ingress-nginx"

    # Parameters is a link to a custom resource containing additional
    # configuration for the controller. This is optional if the controller
    # does not require extra parameters.
    parameters: {}

  # labels to add to the pod container metadata
  podLabels: {}
  #  key: value

  ## Security Context policies for controller pods
  ##
  podSecurityContext: {}

  ## See https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/ for
  ## notes on enabling and using sysctls
  ###
  sysctls: {}
  # sysctls:
  #   "net.core.somaxconn": "8192"

  ## Allows customization of the source of the IP address or FQDN to report
  ## in the ingress status field. By default, it reads the information provided
  ## by the service. If disable, the status field reports the IP address of the
  ## node or nodes where an ingress controller pod is running.
  publishService:
    enabled: true
    ## Allows overriding of the publish service to bind to
    ## Must be <namespace>/<service_name>
    ##
    pathOverride: ""

  ## Limit the scope of the controller
  ##
  scope:
    enabled: false
    namespace: ""   # defaults to $(POD_NAMESPACE)
    # When scope.enabled == false, instead of watching all namespaces, we watching namespaces whose labels
    #   only match with namespaceSelector. Format like foo=bar. Defaults to empty, means watching all namespaces.
    namespaceSelector: ""

  ## Allows customization of the configmap / nginx-configmap namespace
  ##
  configMapNamespace: ""   # defaults to $(POD_NAMESPACE)

  ## Allows customization of the tcp-services-configmap
  ##
  tcp:
    configMapNamespace: ""   # defaults to $(POD_NAMESPACE)
    ## Annotations to be added to the tcp config configmap
    annotations: {}

  ## Allows customization of the udp-services-configmap
  ##
  udp:
    configMapNamespace: ""   # defaults to $(POD_NAMESPACE)
    ## Annotations to be added to the udp config configmap
    annotations: {}

  # Maxmind license key to download GeoLite2 Databases
  # https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases
  maxmindLicenseKey: ""

  ## Additional command line arguments to pass to nginx-ingress-controller
  ## E.g. to specify the default SSL certificate you can use
  ## extraArgs:
  ##   default-ssl-certificate: "<namespace>/<secret_name>"
  extraArgs: {}

  ## Additional environment variables to set
  extraEnvs: []
  # extraEnvs:
  #   - name: FOO
  #     valueFrom:
  #       secretKeyRef:
  #         key: FOO
  #         name: secret-resource

  ## DaemonSet or Deployment
  ##
  kind: Deployment

  ## Annotations to be added to the controller Deployment or DaemonSet
  ##
  annotations: {}
  #  keel.sh/pollSchedule: "@every 60m"

  ## Labels to be added to the controller Deployment or DaemonSet
  ##
  labels: {}
  #  keel.sh/policy: patch
  #  keel.sh/trigger: poll


  # The update strategy to apply to the Deployment or DaemonSet
  ##
  updateStrategy: {}
  #  rollingUpdate:
  #    maxUnavailable: 1
  #  type: RollingUpdate

  # minReadySeconds to avoid killing pods before we are ready
  ##
  minReadySeconds: 0

%{ if var.node_group_workload_class != "" ~}
  # It's OK to be deployed to the tools pool, too
  tolerations:
    - key: "group.msg.cloud.kubernetes/workload"
      operator: "Equal"
      value: ${var.node_group_workload_class}
      effect: "NoSchedule"
%{ endif ~}

  affinity:
%{ if var.node_group_workload_class != "" ~}
    # Encourages deployment to the tools pool
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: "group.msg.cloud.kubernetes/workload"
                operator: In
                values:
                  - ${var.node_group_workload_class}
%{ endif ~}
    # Avoid running replicas on the same node
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                - ingress-nginx
              - key: app.kubernetes.io/instance
                operator: In
                values:
                - ingress-nginx
              - key: app.kubernetes.io/component
                operator: In
                values:
                - controller
            topologyKey: kubernetes.io/hostname

  ## Topology spread constraints rely on node labels to identify the topology domain(s) that each Node is in.
  ## Ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/
  ##
  topologySpreadConstraints: []
    # - maxSkew: 1
    #   topologyKey: failure-domain.beta.kubernetes.io/zone
    #   whenUnsatisfiable: DoNotSchedule
    #   labelSelector:
    #     matchLabels:
  #       app.kubernetes.io/instance: ingress-nginx-internal

  ## terminationGracePeriodSeconds
  ## wait up to five minutes for the drain of connections
  ##
  terminationGracePeriodSeconds: 300

  ## Node labels for controller pod assignment
  ## Ref: https://kubernetes.io/docs/user-guide/node-selection/
  ##
  nodeSelector:
    kubernetes.io/os: linux

  startupProbe:
    httpGet:
      # should match container.healthCheckPath
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 5
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 5
  livenessProbe:
    httpGet:
      # should match container.healthCheckPath
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 5
  readinessProbe:
    httpGet:
      # should match container.healthCheckPath
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 3


  # Path of the health check endpoint. All requests received on the port defined by
  # the healthz-port parameter are forwarded internally to this path.
  healthCheckPath: "/healthz"

  # Address to bind the health check endpoint.
  # It is better to set this option to the internal node address
  # if the ingress nginx controller is running in the hostNetwork: true mode.
  healthCheckHost: ""

  ## Annotations to be added to controller pods
  ##
  podAnnotations: {}

  replicaCount: 1

  minAvailable: 1

  # Define requests resources to avoid probe issues due to CPU utilization in busy nodes
  # ref: https://github.com/kubernetes/ingress-nginx/issues/4735#issuecomment-551204903
  # Ideally, there should be no limits.
  # https://engineering.indeedblog.com/blog/2019/12/cpu-throttling-regression-fix/
  resources:
    #  limits:
    #    cpu: 100m
    #    memory: 90Mi
    requests:
      cpu: 100m
      memory: 90Mi

  # Mutually exclusive with keda autoscaling
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 11
    targetCPUUtilizationPercentage: 50
    targetMemoryUtilizationPercentage: 50
    behavior: {}
      # scaleDown:
      #   stabilizationWindowSeconds: 300
      #  policies:
      #   - type: Pods
      #     value: 1
      #     periodSeconds: 180
      # scaleUp:
      #   stabilizationWindowSeconds: 300
      #   policies:
      #   - type: Pods
      #     value: 2
    #     periodSeconds: 60

  autoscalingTemplate: []
  # Custom or additional autoscaling metrics
  # ref: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#support-for-custom-metrics
  # - type: Pods
  #   pods:
  #     metric:
  #       name: nginx_ingress_controller_nginx_process_requests_total
  #     target:
  #       type: AverageValue
  #       averageValue: 10000m

  ## Enable mimalloc as a drop-in replacement for malloc.
  ## ref: https://github.com/microsoft/mimalloc
  ##
  enableMimalloc: true

  ## Override NGINX template
  customTemplate:
    configMapName: ""
    configMapKey: ""

  service:
    enabled: true

    annotations: {}

    labels: {}
    # clusterIP: ""

    ## List of IP addresses at which the controller services are available
    ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
    ##
    externalIPs: []

    # loadBalancerIP: ""
    loadBalancerSourceRanges: []

    enableHttp: true
    enableHttps: true

    ## Set external traffic policy to: "Local" to preserve source IP on providers supporting it.
    ## Ref: https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-typeloadbalancer
    # externalTrafficPolicy: ""

    ## Must be either "None" or "ClientIP" if set. Kubernetes will default to "None".
    ## Ref: https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies
    # sessionAffinity: ""

    ## Specifies the health check node port (numeric port number) for the service. If healthCheckNodePort isn’t specified,
    ## the service controller allocates a port from your cluster’s NodePort range.
    ## Ref: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip
    # healthCheckNodePort: 0

    ## Represents the dual-stack-ness requested or required by this Service. Possible values are
    ## SingleStack, PreferDualStack or RequireDualStack.
    ## The ipFamilies and clusterIPs fields depend on the value of this field.
    ## Ref: https://kubernetes.io/docs/concepts/services-networking/dual-stack/
    ipFamilyPolicy: "SingleStack"

    ## List of IP families (e.g. IPv4, IPv6) assigned to the service. This field is usually assigned automatically
    ## based on cluster configuration and the ipFamilyPolicy field.
    ## Ref: https://kubernetes.io/docs/concepts/services-networking/dual-stack/
    ipFamilies:
      - IPv4

    ports:
      http: 80
      https: 443

    targetPorts:
      http: http
      https: https

    type: LoadBalancer

    external:
      enabled: true

    ## Enables an additional internal load balancer (besides the external one).
    ## Annotations are mandatory for the load balancer to come up. Varies with the cloud service.
    internal:
      enabled: false
      annotations: {}

      # loadBalancerIP: ""

      ## Restrict access For LoadBalancer service. Defaults to 0.0.0.0/0.
      loadBalancerSourceRanges: []

      ## Set external traffic policy to: "Local" to preserve source IP on
      ## providers supporting it
      ## Ref: https://kubernetes.io/docs/tutorials/services/source-ip/#source-ip-for-services-with-typeloadbalancer
      # externalTrafficPolicy: ""

  extraContainers: []
  ## Additional containers to be added to the controller pod.
  ## See https://github.com/lemonldap-ng-controller/lemonldap-ng-controller as example.
  #  - name: my-sidecar
  #    image: nginx:latest
  #  - name: lemonldap-ng-controller
  #    image: lemonldapng/lemonldap-ng-controller:0.2.0
  #    args:
  #      - /lemonldap-ng-controller
  #      - --alsologtostderr
  #      - --configmap=$(POD_NAMESPACE)/lemonldap-ng-configuration
  #    env:
  #      - name: POD_NAME
  #        valueFrom:
  #          fieldRef:
  #            fieldPath: metadata.name
  #      - name: POD_NAMESPACE
  #        valueFrom:
  #          fieldRef:
  #            fieldPath: metadata.namespace
  #    volumeMounts:
  #    - name: copy-portal-skins
  #      mountPath: /srv/var/lib/lemonldap-ng/portal/skins

  extraVolumeMounts: []
  ## Additional volumeMounts to the controller main container.
  #  - name: copy-portal-skins
  #   mountPath: /var/lib/lemonldap-ng/portal/skins

  extraVolumes: []
  ## Additional volumes to the controller pod.
  #  - name: copy-portal-skins
  #    emptyDir: {}

  extraInitContainers: []
  ## Containers, which are run before the app containers are started.
  # - name: init-myservice
  #   image: busybox
  #   command: ['sh', '-c', 'until nslookup myservice; do echo waiting for myservice; sleep 2; done;']

  admissionWebhooks:
    annotations: {}
    enabled: true
    failurePolicy: Fail
    # timeoutSeconds: 10
    port: 8443
    certificate: "/usr/local/certificates/cert"
    key: "/usr/local/certificates/key"
    namespaceSelector: {}
    objectSelector: {}

    # Use an existing PSP instead of creating one
    existingPsp: ""

    service:
      annotations: {}
      # clusterIP: ""
      externalIPs: []
      # loadBalancerIP: ""
      loadBalancerSourceRanges: []
      servicePort: 443
      type: ClusterIP

    createSecretJob:
      resources: {}
        # limits:
        #   cpu: 10m
        #   memory: 20Mi
        # requests:
        #   cpu: 10m
      #   memory: 20Mi

    patchWebhookJob:
      resources: {}

    patch:
      enabled: true
      ## Provide a priority class name to the webhook patching job
      ##
      priorityClassName: ""
      podAnnotations: {}
      nodeSelector:
        kubernetes.io/os: linux
      tolerations: []
      runAsUser: 2000

  metrics:
    port: 10254
    # if this port is changed, change healthz-port: in extraArgs: accordingly
    enabled: true

    service:
      annotations: {}
      # prometheus.io/scrape: "true"
      # prometheus.io/port: "10254"

      # clusterIP: ""

      ## List of IP addresses at which the stats-exporter service is available
      ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
      ##
      externalIPs: []

      # loadBalancerIP: ""
      loadBalancerSourceRanges: []
      servicePort: 10254
      type: ClusterIP
      # externalTrafficPolicy: ""
      # nodePort: ""

    serviceMonitor:
      enabled: false
      additionalLabels: {}
      # The label to use to retrieve the job name from.
      # jobLabel: "app.kubernetes.io/name"
      namespace: ""
      namespaceSelector: {}
      # Default: scrape .Release.Namespace only
      # To scrape all, use the following:
      # namespaceSelector:
      #   any: true
      scrapeInterval: 30s
      # honorLabels: true
      targetLabels: []
      metricRelabelings: []

    prometheusRule:
      enabled: false
      additionalLabels: {}
      # namespace: ""
      rules: []
        # # These are just examples rules, please adapt them to your needs
        # - alert: NGINXConfigFailed
        #   expr: count(nginx_ingress_controller_config_last_reload_successful == 0) > 0
        #   for: 1s
        #   labels:
        #     severity: critical
        #   annotations:
        #     description: bad ingress config - nginx config test failed
        #     summary: uninstall the latest ingress changes to allow config reloads to resume
        # - alert: NGINXCertificateExpiry
        #   expr: (avg(nginx_ingress_controller_ssl_expire_time_seconds) by (host) - time()) < 604800
        #   for: 1s
        #   labels:
        #     severity: critical
        #   annotations:
        #     description: ssl certificate(s) will expire in less then a week
        #     summary: renew expiring certificates to avoid downtime
        # - alert: NGINXTooMany500s
        #   expr: 100 * ( sum( nginx_ingress_controller_requests{status=~"5.+"} ) / sum(nginx_ingress_controller_requests) ) > 5
        #   for: 1m
        #   labels:
        #     severity: warning
        #   annotations:
        #     description: Too many 5XXs
        #     summary: More than 5% of all requests returned 5XX, this requires your attention
        # - alert: NGINXTooMany400s
        #   expr: 100 * ( sum( nginx_ingress_controller_requests{status=~"4.+"} ) / sum(nginx_ingress_controller_requests) ) > 5
        #   for: 1m
        #   labels:
        #     severity: warning
        #   annotations:
        #     description: Too many 4XXs
      #     summary: More than 5% of all requests returned 4XX, this requires your attention

  ## Improve connection draining when ingress controller pod is deleted using a lifecycle hook:
  ## With this new hook, we increased the default terminationGracePeriodSeconds from 30 seconds
  ## to 300, allowing the draining of connections up to five minutes.
  ## If the active connections end before that, the pod will terminate gracefully at that time.
  ## To effectively take advantage of this feature, the Configmap feature
  ## worker-shutdown-timeout new value is 240s instead of 10s.
  ##
  lifecycle:
    preStop:
      exec:
        command:
          - /wait-shutdown

  priorityClassName: ""

## Rollback limit
##
revisionHistoryLimit: 10

## Default 404 backend
##
defaultBackend:
  ##
  enabled: false

## Enable RBAC as per https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/rbac.md and https://github.com/kubernetes/ingress-nginx/issues/266
rbac:
  create: true
  scope: false

# If true, create & use Pod Security Policy resources
# https://kubernetes.io/docs/concepts/policy/pod-security-policy/
podSecurityPolicy:
  enabled: false

serviceAccount:
  create: true
  name: ""
  automountServiceAccountToken: true

## Optional array of imagePullSecrets containing private registry credentials
## Ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
imagePullSecrets: []
# - name: secretName

# TCP service key:value pairs
# Ref: https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/exposing-tcp-udp-services.md
##
tcp: {}
#  8080: "default/example-tcp-svc:9000"

# UDP service key:value pairs
# Ref: https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/exposing-tcp-udp-services.md
##
udp: {}
#  53: "kube-system/kube-dns:53"

# A base64ed Diffie-Hellman parameter
# This can be generated with: openssl dhparam 4096 2> /dev/null | base64
# Ref: https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples/customization/ssl-dh-param
dhParam:
EOT
}

resource helm_release nginx {
  chart = "ingress-nginx"
  version = "4.0.8"
  name = var.helm_release_name
  dependency_update = true
  atomic = true
  cleanup_on_fail = true
  namespace = var.kubernetes_namespace_name
  create_namespace = true
  repository = "https://kubernetes.github.io/ingress-nginx"
  values = [ local.nginx_values ]
  wait = true

  set {
    name = "controller.replicaCount"
    value = "2"
  }
}
