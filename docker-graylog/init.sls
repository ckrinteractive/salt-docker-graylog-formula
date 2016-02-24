{% set image_name = 'graylog2/allinone' %}
{% set container_name = 'graylog' %}
{% set web_host_port = salt['pillar.get']('graylog:web_port', '8080') %}
{% set input_host_port = salt['pillar.get']('graylog:input_port', '12201') %}
{% set bind_ip = salt['pillar.get']('graylog:bind_ip') %}
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


{{ image_name }}-pulled:
  docker.pulled:
     - name: {{ image_name }}
     - force: True
     - order: 100

{{ container_name }}-stop-if-old:
  cmd.run:
    - name: docker stop {{ container_name }}
    - unless: docker inspect --format "\{\{ .Image \}\}" {{ container_name }} | grep $(docker images | grep "{{ image_name }}" | awk '{ print $3 }')
    - require:
      - docker: {{ image_name }}-pulled
    - order: 111

{{ container_name }}-remove-if-old:
  cmd.run:
    - name: docker rm {{ container_name }}
    - unless: docker inspect --format "\{\{ .Image \}\}" {{ container_name }} | grep $(docker images | grep "{{ image_name }}" | awk '{ print $3 }')
    - require:
      - cmd: {{ container_name }}-stop-if-old
    - order: 112

{{ image_name }}-container:
  require:
    - docker: {{ image_name }}-pulled
  docker.installed:
    - name: {{ container_name }}
    - image: {{ image_name }}
    - environment:
      {% for env_var, env_val in env_vars.items() -%}
        - {{ env_var }}: {{ env_val }}
      {% endfor %}
    - volumes:
      {% for c_path, h_path in volume_map.items() %}
      - "{{ h_path }}:{{ c_path }}"
      {% endfor %}
    - order: 120

{{ container_name }}:
  require:
    - docker: {{ image_name }}-container
  docker.running:
    - container: {{ container_name }}
    - image: {{ image_name }}
    - restart_policy: always
    - volumes:
      {% for c_path, h_path in volume_map.items() %}
        {{ h_path }}:
            bind: {{ c_path }}
            ro: False
      {% endfor %}
    - ports:
        - "9000/tcp":
            HostIp: {{ bind_ip }}
            HostPort: {{ web_host_port }}
        - "12201/udp":
            HostIp: {{ bind_ip }}
            HostPort: {{ input_host_port }}
    - order: 121
