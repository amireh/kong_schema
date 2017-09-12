require 'kong'

module Kong
  class Upstream
    # monkey patch to make it return only "active" targets
    #
    # see https://github.com/Mashape/kong/issues/2876#issuecomment-328667296
    # see https://github.com/kontena/kong-client-ruby/blob/master/lib/kong/upstream.rb#L17
    def targets
      targets   = []
      json_data = Client.instance.get("#{API_END_POINT}#{self.id}/targets")

      if json_data['data']
        json_data['data'].each do |target_data|
          targets << Target.new(target_data)
        end
      end

      by_target = targets.reduce({}) do |map, target|
        map[target.target] ||= []
        map[target.target] << target
        map
      end

      by_target.keys.reduce([]) do |list, key|
        target = by_target[key].sort_by { |x| x.attributes[:created_at].to_i }.last

        if target.active?
          list.push(target)
        else
          list
        end
      end
    end
  end
end
