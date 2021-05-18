{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import htpasswd as htp -%}
{% from tplroot ~ '/macro.jinja' import format_kwargs -%}

include:
  - .hooks

{% if htp.files -%}
  {#- Iterate over htpasswd files in pillars #}
  {%- for f_id, f_data in htp.files|dictsort %}
    {%- set file = f_data.file %}
htpasswd_manage_{{ f_id }}_parent_dir:
  file.directory:
    - name: {{ salt['file.dirname'](file) }}
    {{- format_kwargs(f_data.get('parent_dir_perms', {})) }}

    {#- Iterate over users in one htpasswd file #}
    {%- for user_id, user_data in f_data.users|dictsort %}
      {%- set ensure = user_data.pop('ensure', 'present') %}
htpasswd_manage_{{ f_id }}_{{ user_id }}:
  webutil:
    - htpasswd_file: '{{ file }}'
    - name: {{ user_data.pop('name', user_id) }}
      {%- if ensure == 'absent' %}
    - user_absent
        {%- if 'runas' in user_data and user_data.runas %}
    - runas: {{ user_data.runas }}
        {%- endif %}
      {%- elif ensure == 'present' %}
    - user_exists
    {{- format_kwargs(user_data) }}
      {%- endif %}
    - require:
      - file: htpasswd_manage_{{ f_id }}_parent_dir
      {#- Attach hooks if at least one is present #}
      {%- if 'hooks' in f_data and f_data.hooks %}
    - watch_in:
        {%- if 'service' in f_data.hooks and f_data.hooks.service %}
          {%- set service_action = f_data.hooks.service.get('action', '') if f_data.hooks.service.get('action', '') in ('start', 'restart', 'reload') else 'restart' %}
          {%- set service_name = f_data.hooks.service.get('name', '') %}
      - module: htpasswd_hooks_{{ f_id }}_{{ service_action }}_<{{ service_name }}>_service
        {%- endif %}
      {%- endif %}

    {%- endfor %}
  {%- endfor %}

{% else -%}
htpasswd_manage_no_files_notice:
  test.show_notification:
    - name: htpasswd_manage_no_files_notice
    - text: |
        No htpasswd files are defined in pillars.

{% endif -%}
