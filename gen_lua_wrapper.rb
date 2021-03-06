#! /usr/bin/ruby

require 'xcodeproj'
require 'stringio'
require 'yaml'

$proj = nil
$prefix = ''
$proj_path = '/home/yangc/testconfuse/com.test.confuse/frameworks/runtime-src/proj.ios_mac/com.test.confuse.xcodeproj'

def gen_dir()
    src = $proj.main_group.find_subpath(File.join('Resources', 'src'), true)
    src_path = src.real_path.to_s
    dir_path = '%s/cocos/custom' % src_path
    if File.exists?(dir_path)
        Dir.foreach(dir_path) do |file_path|
            if file_path != '.' and file_path != '..'
                File.delete('%s/%s' % [dir_path, file_path])
            end
        end
        Dir.rmdir(dir_path)
    end
    Dir.mkdir(dir_path)
end

def gen_func(old_class, new_class, old_func, new_func)
    func_body = Array.new()
    func_body << 'function %s.%s(...)' % [old_class, old_func]
    func_body << '    return %s.%s(...)' % [new_class, new_func]
    func_body << 'end'
    return func_body
end

def gen_meta_file(meta)
    src = $proj.main_group.find_subpath(File.join('Resources', 'src'), true)
    src_path = src.real_path.to_s
    init_path = '%s/cocos/custom/init.lua' % src_path
    File.open(init_path, 'a+') do |init_file|
        input_str = '%s = %s' % [meta['old'], meta['new']]
        init_file.puts ''
        init_file.puts input_str
        init_file.puts ''
        if meta['functions']
            meta['functions'].each do |fm|
                gen_func(meta['old'], meta['new'], fm['old'], fm['new']).each do |line|
                    init_file.puts line
                end
            end
        end
    end
end

# temp proc
def gen_prefix()
    src = $proj.main_group.find_subpath(File.join('Resources', 'src'), true)
    src_path = src.real_path.to_s
    init_path = '%s/cocos/custom/init.lua' % src_path
    File.open(init_path, 'a+') do |init_file|
        init_file.puts ''
        init_file.puts '_G["OCPrefix"] = "%s"' % $prefix
        init_file.puts ''
    end
end

def modify_require()
    src = $proj.main_group.find_subpath(File.join('Resources', 'src'), true)
    src_path = src.real_path.to_s
    target_path = '%s/cocos/init.lua' % src_path
    buffer = StringIO.new
    if File.exists?(target_path)
        if !File.open(target_path, 'r').read().include?('require "cocos.custom.init"')
            File.open(target_path, 'r').each_line do |line|
                li = line.chomp
                buffer.puts li
                if li == ']]'
                    buffer.puts ''
                    buffer.puts '-- custom'
                    buffer.puts 'require "cocos.custom.init"'
                    buffer.puts ''
                end
            end
            File.open(target_path, 'w') do |f|
                f.puts buffer.string
            end    
        end
    end
end

def gen_lua(meta)
    gen_dir()
    meta['classes'].each do |mt|
        gen_meta_file(mt)
    end
    gen_prefix()
    modify_require()
end

if ARGV[0] != nil
    $prefix = ARGV[0]
else   
    puts 'input prefix to add:'
    head = gets.chomp
    $prefix = head.length > 0 ? head : $prefix
end

if ARGV[1] != nil
    $proj_path = ARGV[1]
else
    puts 'input xcodeproj file path:'
    path = gets.chomp
    $proj_path = path.length > 0 ? path : $proj_path    
end

if File.exists?($proj_path) and File.directory?($proj_path)
    $proj = Xcodeproj::Project.open($proj_path)
    yaml_path = '%s/lua.yaml' % $proj.main_group.real_path.to_s 
    if File.exists?(yaml_path)
        yaml = YAML.load(File.open(yaml_path))
        gen_lua(yaml)
    end
end