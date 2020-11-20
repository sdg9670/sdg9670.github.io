---
title: "Post about Docker"
layout: archive
permalink: /categories/docker
author_profile: true
---

{% assign posts = site.categories.docker | sort:"date" %}

{% for post in posts %}
  {% include archive-single.html type=page.entries_layout %}
{% endfor %}
