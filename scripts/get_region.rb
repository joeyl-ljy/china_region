require 'open-uri'
require 'nokogiri'
require 'zlib'
require 'csv'

def headers
  {'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8 ',
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Language'=> 'zh-CN,zh;q=0.9',
    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36",
    'Host'=>'www.stats.gov.cn',
    'Pragma'=> 'no-cache',
    'Connection'=>'keep-alive'
  }
end

def get_tjbz(set_new = false ,uri = 'http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm')
  ori_url = "#{uri}/#{(Time.now.to_date.year) -1}/index.html"
  if set_new
    # 最新的统计标准 
    doc = Nokogiri::HTML(Zlib::GzipReader.new(open(uri,headers)),nil, "GB18030")
    link = doc.search('.center_list_contlist li a')
    link_url = link[0].get_attribute("href")
  end
  rescue => e
    ori_url
end

# 取路径的最后一个/前的字符与str拼接
def set_url(link_url, str)
  [link_url.split("/")[0..-2], str].join("/")
end

def set_region_data(s_url, doc_s, s_arr = [],error_arr = [])
  begin
    ###编码问题
    # 使用Nokogiri自带编码，有些中文网页指定的编码是gb2312，其实是GB18030
    # 使用gzip解决Zlib::GzipFile::Error: not in gzip format
    # s_doc = Nokogiri::HTML(open(s_url,headers),nil, "GB18030")
    s_doc = Nokogiri::HTML(Zlib::GzipReader.new(open(s_url,headers)),nil, "GB18030")
    s_nodes = s_doc.search(doc_s)
    s_nodes.each do |s_node|
      s_link = s_node.get_attribute("href")
      if s_link.present?
        link_url = set_url(s_url, s_link)
        s_code = s_link.split("/").last[0..-6]
        s_name = s_node.content
      else
        s_code = s_node.children.first.content
        s_name = s_node.children.last.content
      end
      if s_name.strip.present? && s_code.to_i > 0
        s_arr << {
          code: s_code,
          name: s_name,
          link_url: link_url,
          link: s_link
        }
      end
    end
    rescue => e
      error_arr << {link_url: s_url}
  end
    [s_arr, error_arr]
end

def set_region_each(p_arr, doc_s, c_arr , c_earr, start_code = "0", finish_code = "-1")
  arr = p_arr[start_code.to_i..finish_code.to_i] if p_arr.present?
  if arr.present?
    arr.each do |pa|
      puts "get #{doc_s}"
      c_arr,c_earr = set_region_data(pa[:link_url], ".#{doc_s} td:last-child a", c_arr, c_earr) if pa[:link_url].present?
    end
  end
  [c_arr,c_earr]
end

# 设置文件 
def file_open(file_name)
  puts "new region data to see #{file_name}"
  data_file = File.open(file_name,"w")
  yield(data_file) if block_given?
  data_file.close
end

# 写入内容
def file_write(data_array, data_file, is_all = false)
  data_array.each do |array|
    data_w = (array.is_a? Hash) ?  is_all ? array.to_json : "#{array[:code]},#{array[:name]}" : (array.is_a? Array) ? "#{array.join(",")}": "#{array}"
    data_file.syswrite("#{data_w}\n")
  end
end

def file_write_new(is_all, fil_data,fn)
  efile_name = File.expand_path("../regions/db_#{fn}.csv", __FILE__)
  file_open(efile_name) do |data_file|
    file_write(fil_data, data_file, is_all)
  end    
end

def get_region(s_arr, doc, fn)
  arr = []
  earr = []
  file_name = File.expand_path("../regions/db_#{fn}.csv", __FILE__)
  file_open(file_name) do |data_file|
    s_arr.each do |pa|
      pa = JSON.parse(pa).with_indifferent_access unless pa.is_a? Hash
      arr,earr = set_region_data(pa[:link_url], "#{doc}", arr, earr) if pa[:link_url].present?
      break if earr.present?
    end
    file_write(arr, data_file)
    is_all = true
    if earr.blank?
      file_params = "arr"
      fil_data = arr
    else
      file_params = "earr"
      fil_data = earr
    end
    file_write_new(is_all, fil_data, [fn,file_params].join("_"))
  end
  arr
end

def set_provinces(set_new = false, uri = 'http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm')
  if set_new
    link_url = get_tjbz(set_new, uri)
    arr = [{
      link_url: set_url(link_url, link_url.split("/").last)
    }]
    p_arr , p_earr = get_region(arr, '.provincetr td a', "p_arr")
  else
    p_arr , p_earr = [
      {:code=>"11", :name=>"北京市", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/11.html", :link=>"11.html"},
      {:code=>"12", :name=>"天津市", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/12.html", :link=>"12.html"},
      {:code=>"13", :name=>"河北省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/13.html", :link=>"13.html"},
      {:code=>"14", :name=>"山西省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/14.html", :link=>"14.html"},
      {:code=>"15", :name=>"内蒙古自治区", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/15.html", :link=>"15.html"},
      {:code=>"21", :name=>"辽宁省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/21.html", :link=>"21.html"},
      {:code=>"22", :name=>"吉林省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/22.html", :link=>"22.html"},
      {:code=>"23", :name=>"黑龙江省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/23.html", :link=>"23.html"},
      {:code=>"31", :name=>"上海市", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/31.html", :link=>"31.html"},
      {:code=>"32", :name=>"江苏省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/32.html", :link=>"32.html"},
      {:code=>"33", :name=>"浙江省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/33.html", :link=>"33.html"},
      {:code=>"34", :name=>"安徽省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/34.html", :link=>"34.html"},
      {:code=>"35", :name=>"福建省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/35.html", :link=>"35.html"},
      {:code=>"36", :name=>"江西省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/36.html", :link=>"36.html"},
      {:code=>"37", :name=>"山东省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/37.html", :link=>"37.html"},
      {:code=>"41", :name=>"河南省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/41.html", :link=>"41.html"},
      {:code=>"42", :name=>"湖北省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/42.html", :link=>"42.html"},
      {:code=>"43", :name=>"湖南省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/43.html", :link=>"43.html"},
      {:code=>"44", :name=>"广东省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/44.html", :link=>"44.html"},
      {:code=>"45", :name=>"广西壮族自治区", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/45.html", :link=>"45.html"},
      {:code=>"46", :name=>"海南省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/46.html", :link=>"46.html"},
      {:code=>"50", :name=>"重庆市", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/50.html", :link=>"50.html"},
      {:code=>"51", :name=>"四川省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/51.html", :link=>"51.html"},
      {:code=>"52", :name=>"贵州省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/52.html", :link=>"52.html"},
      {:code=>"53", :name=>"云南省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/53.html", :link=>"53.html"},
      {:code=>"54", :name=>"西藏自治区", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/54.html", :link=>"54.html"},
      {:code=>"61", :name=>"陕西省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/61.html", :link=>"61.html"},
      {:code=>"62", :name=>"甘肃省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/62.html", :link=>"62.html"},
      {:code=>"63", :name=>"青海省", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/63.html", :link=>"63.html"},
      {:code=>"64", :name=>"宁夏回族自治区", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/64.html", :link=>"64.html"},
      {:code=>"65", :name=>"新疆维吾尔自治区", :link_url=>"http://www.stats.gov.cn/tjsj/tjbz/tjyqhdmhcxhfdm/2017/65.html", :link=>"65.html"}
    ],[]
  end
end

def set_file_path(fn)
  File.expand_path("../regions/db_#{fn}.csv", __FILE__)
end

def get_by_file(fn, cn, doc)
  origion_file = File.expand_path("../regions/db_#{fn}.csv", __FILE__)
  s_arr = File.open(origion_file)
  get_region(s_arr, doc, cn)
end

def file_join(file_names, new_file_name = 'vvv')
   file_open(set_file_path(new_file_name)) do |data_file| 
     ARGV.replace file_names.split(",").map{|x| set_file_path(x)}
     data_file.syswrite("code,name\n")
     data_file.syswrite(ARGF.read)
   end
end

def mapping_data(new_file_name, file_names = nil)
  new_file = new_file_name ? set_file_path(new_file_name) : set_file_path("#{Time.now.to_date}")
  origion_file = file_names ? set_file_path(file_names) : File.expand_path("../../data/db.csv", __FILE__)
  puts "read origion_file"
  a = CSV.read(origion_file)
  puts "read new_file"
  b = CSV.read(new_file)
  all = a & b
  file_write_new(false, all,"mappinga_#{Time.now.to_date}")
  c = (a - all)
  file_write_new(false, c,"mappingo_#{Time.now.to_date}")
  d = (b - all)
  file_write_new(false, d,"mappingn_#{Time.now.to_date}")
end