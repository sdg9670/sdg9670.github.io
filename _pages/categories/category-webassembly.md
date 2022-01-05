---
title: "Post about Webassembly"
layout: archive
permalink: /categories/webassembly
author_profile: true
---

{% assign posts = site.categories.webassembly | sort:"date" | reverse %}

{% for post in posts %}
{% include archive-single.html type=page.entries_layout %}
{% endfor %}
