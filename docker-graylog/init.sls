{% set image_name = 'graylog2/allinone' %}
{% set container_name = 'graylog' %}
{% set web_host_port = salt['pillar.get']('graylog:web_port', '9000') %}
{% set gelf_input_port = salt['pillar.get']('graylog:gelf_input_port', '12201') %}
{% set syslog_input_port = salt['pillar.get']('graylog:syslog_input_port', '514') %}
{% set host_ip = salt['grains.get']('ip4_interfaces:eth0:0') %}
{% set env_vars = {
  'GRAYLOG_PASSWORD':	salt['pillar.get']('graylog:password', ''),
  'GRAYLOG_USERNAME':	salt['pillar.get']('graylog:username', 'admin'),
  'GRAYLOG_TIMEZONE':	salt['pillar.get']('graylog:timezone', 'America/New_York'),
  'GRAYLOG_SMTP_SERVER': salt['pillar.get']('graylog:smtp_server'),
  'GRAYLOG_RETENTION':	salt['pillar.get']('graylog:retention'),
  'GRAYLOG_SERVER_SECRET':	salt['pillar.get']('graylog:secret'),
  'ES_MEMORY':	salt['pillar.get']('graylog:es_memory', '4g'),
} %}
{% set volume_map = {
  '/var/opt/graylog/data': salt['pillar.get']('graylog:data_dir', '/graylog-data'),
} %}


{{ image_name }}:
  dockerng.image_present:
     - force: True

{{ container_name }}:
  require:
    - dockerng: {{ image_name }}
  docker.installed:
    - name: {{ container_name }}
    - image: {{ image_name }}
    - environment:
      {% for env_var, env_val in env_vars.items() -%}
        - {{ env_var }}: "{{ env_val }}"
      {% endfor %}
    - binds:
      {% for c_path, h_path in volume_map.items() %}
      - "{{ h_path }}:{{ c_path }}"
      {% endfor %}
    - port_bindings:
      - {{ host_ip }}:{{ web_host_port }}:9000/tcp
      - {{ host_ip }}:{{ gelf_input_port }}:12201/udp
      - {{ host_ip }}:{{ syslog_input_port }}:514/udp
    - restart_policy: always
