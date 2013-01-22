###

Copyright 2012-2013 Mikko Apo

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

###

"use strict"

# simple assert method which checks key-value pairs from a Hash
# - makes it easy to check many items from page
# - Hash key is used as jquery selector
# - value can contain either one item or a list of values. selector needs to find the same number of elements
# - value can contain either strings or regex objects
this.assertElements = (source, assert_map) ->
  if !assert_map?
    assert_map = source
    source = $("body")
  else
    source = $(source)
  for key, asserts of assert_map
    if !Array.isArray(asserts)
      asserts = [asserts]
    nodes = source.find(key)
    selector = key
    if nodes.size() == 0
      selector = ".#{key}"
      nodes = source.find(selector)
    if asserts.length != nodes.size()
      if nodes.size() == 0
        throw "Selector '#{selector}' did not match any nodes! There are #{asserts.length} asserts."
      else
        throw "Selector '#{selector}' matched #{nodes.size()} but there are #{asserts.length} asserts."
    for i in [0..(asserts.length-1)]
      a = asserts[i]
      element = nodes.get(i)
      type = $.type(a)
      text = $(element).text()
      if type == "regexp"
        if !a.test(text)
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match RegEx '#{a}'"
      else if type == "string"
        if a != text
          throw "Selector #{selector} returned #{nodes.size()} elements, item at index #{i} '#{text}' does not match '#{a}'"
      else
        assertElements(element, a)

# simple templating mechanism that handles
# - templates from script tags
# - fills templates based on key-value pairs from parameter object, lookup either class (property name) or jquery selector string (string)
# - renders single object or list of objects based on parameter count
# - supports modifier function for named fields
# - gFun is a global function applied to all matched element
this.renderElements = (destId, templateId, data = {}, gFun = null) ->
  template_source = $(templateId)
  if !template_source.is("script")
    throw "Template '#{templateId}' is not a script tag!"
  if template_source.size() == 0
    throw "Could not locate template script tag for '#{templateId}'"
  dest = $(destId)
  if dest.size() == 0
    throw "Could not locate destination '#{destId}'"
  destTag = document.createElement(dest[0].tagName)

  if !Array.isArray(data)
    data = [data]
  destTag.innerHTML = template_source.html()
  original_template = destTag
  clone = data.length > 1
  # repeat for every item in data, good for rendering a list
  for item in data
    template = original_template
    if clone
      template = original_template.cloneNode(true)
    fillTemplate($(template), item, gFun)
    while template.hasChildNodes()
      dest.append template.removeChild(template.firstChild)
  if clone
    dest
  else
    template

fillTemplate = (template, item, gFun) ->
  # go throug every named key-value pair in item
  for key, values of item
    if !Array.isArray(values)
      values = [values]
    nodes = template.find(key)
    if nodes.size() == 0
      nodes = template.find(".#{key}")
    # repeat for every matching node
    for node in nodes
      fillNode(key, node, values, gFun)

fillNode = (key, node, values, gFun) ->
  node = jQuery(node)
  for value in values
    type = $.type(value)
    # modifier function is applied to the selected node
    if type == "function"
      value(node)
    # object's values are applied to the selected node
#    if type == "object"
#      fillNode(node, value)
     # each item in array generates a new child
#    if type == "array"
#      parent = node.parent()
#      node.detach()
#      for data in value
#        newNode = node.clone()
#        fillNode(newNode, data)
#        parent.append(newNode)
    # other values are set as text
    else
      node.text value
    if gFun
      gFun(key, value, node)
