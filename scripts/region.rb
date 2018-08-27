require_relative 'get_region.rb'

if ARGV[0] == 'all'
  # desc "get all region info from web"
  set_new  = ARGV[1] == 'new'
  P_aa, P_earr = set_provinces(set_new, ARGV[1])
  _start_time = Time.now
  c_arr = []
  d_arr = []
  s_arr = []
  x_arr = []
  c_earr = []
  d_earr = []
  s_earr = []
  x_earr = []
  p_arr, p_earr = P_aa, P_earr
  c_arr,c_earr = get_region(p_arr, ".citytr td:last-child a", "c")
  d_arr,d_earr = get_region(c_arr, ".countytr td:last-child a", "d")
  s_arr,s_earr = get_region(d_arr, ".towntr td:last-child a", "s")
  x_arr,x_earr = get_region(s_arr, "tr.villagetr", "x")
  _finish_time = Time.now
  puts "----------------------- Cost #{(_finish_time - _start_time).to_i} seconds -----------------------"
end

if ARGV[0] == 'mapping'
  # desc "mapping origion data"
  _start_time1 = Time.now
  mapping_data(ARGV[1], ARGV[2])
  _finish_time1 = Time.now
  puts "----------------------- Cost #{(_finish_time1 - _start_time1).to_i} seconds -----------------------"
end

if ARGV[0] == 'file'
  # desc "get region info from file"
  get_by_file(ARGV[1], ARGV[2], ARGV[3])
end

if ARGV[0] == 'merge'
  # desc "merge file info to new file"
  file_names = ARGV[1]
  new_file_name = ARGV[2]
  file_join(file_names, new_file_name)
end