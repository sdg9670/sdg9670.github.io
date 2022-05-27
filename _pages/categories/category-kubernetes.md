---
title: "Post about Kubernetes"
layout: archive
permalink: /categories/docker
author_profile: true
---

{% assign posts = site.categories.kubernetes | sort:"date" | reverse %}

{% for post in posts %}
{% include archive-single.html type=page.entries_layout %}
{% endfor %}
