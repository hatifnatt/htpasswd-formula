{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import htpasswd as htp -%}
{% from tplroot ~ '/macro.jinja' import format_kwargs -%}

{%- for f_id, f_data in htp.files|dictsort %}
  {%- if 'hooks' in f_data and f_data.hooks %}
    {#- Service hook #}
    {%- if 'service' in f_data.hooks and f_data.hooks.service %}
      {%- set service_action = f_data.hooks.service.get('action', '') if f_data.hooks.service.get('action', '') in ('start', 'restart', 'reload') else 'restart' %}
      {%- set service_name = f_data.hooks.service.get('name', '') %}
htpasswd_hooks_{{ f_id }}_{{ service_action }}_<{{ service_name }}>_service:
  module.wait:
      {%- if 'module.run' in salt['config.get']('use_superseded', [])
              or grains['saltversioninfo'] >= [3005] %}
    - service.{{ service_action }}:
      - name: {{ service_name }}
      {%- else %}
    - name: service.{{ service_action }}
    - m_name: {{ service_name }}
      {%- endif %}
    - onlyif: test -f {{ f_data.file }}
    {%- endif %}

  {%- else %}
htpasswd_hooks_{{ f_id }}_no_hooks_defined_notice:
  test.show_notification:
    - name: htpasswd_hooks_{{ f_id }}_no_hooks_defined_notice
    - text: |
        No hooks are defined for '{{ f_id }}' ({{ f_data.file }}) file in pillars.

  {%- endif %}
{% endfor -%}
