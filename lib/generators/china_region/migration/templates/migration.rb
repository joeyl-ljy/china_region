class CreateChinaRegions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :china_regions, comment: '区域划分代码表' do |t|
      t.string :code, null: false, comment: '区划代码'
      t.string :name, comment: '名称'
      t.string :pinyin_cap, comment: '拼音'
      t.string :pinyin_abbr, comment: '简拼'
      t.timestamps
    end

    add_index :china_regions, :code, unique: true
    add_index :china_regions, :name
  end

  def self.down
    drop_table :china_regions
  end
end
