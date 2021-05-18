{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import htpasswd as htp -%}

htpasswd_install:
  pkg.installed:
    - name: {{ htp.pkg }}
