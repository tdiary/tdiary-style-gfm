$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tdiary/core_ext'
require 'tdiary/comment_manager'
require 'tdiary/referer_manager'
require 'tdiary/style'
require 'tdiary/style/gfm'

TDiary::Style::GfmDiary.send(:include, TDiary::Style::BaseDiary)
TDiary::Style::GfmSection.send(:include, TDiary::Style::BaseSection)
