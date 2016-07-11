@ReadView = React.createClass
  render: ->
    <CSMReader root={@props.data[0]} />


CSMReader = React.createClass
  getInitialState: ->
    dash_string = location.href.split('#')[1]
    if dash_string? and dash_string.length
      nav_params = dash_string.split(',')
    else
      nav_params = []

    nav_params: nav_params

  render: ->
    # 根据 dash_param 获取 current_node
    current_node = @props.root
    nav_params = @state.nav_params
    bread_arr = [current_node]

    for x in nav_params
      nav_param = x.split(':')
      path_idx = nav_param[0]
      node_idx = nav_param[1]
      path = current_node.paths[path_idx]
      current_node = path.nodes[node_idx]
      bread_arr.push current_node

    <div className='csm-reader'>
      <NodeContentNavbar bread_arr={bread_arr} nav_params={@state.nav_params} reader={@} />
      <NodeContent ref='nc' node={current_node} reader={@} />
      <Sharebar />
    </div>

  nav_into: (nav_param)->
    nav_params = @state.nav_params
    nav_params.push nav_param

    @nav_to nav_params

  nav_to: (nav_params)->
    @setState {
      nav_params: nav_params
    }, =>
      location.href = "/views/read##{nav_params.join(',')}"



NodeContentNavbar = React.createClass
  render: ->
    <div className='navbar'>
    {
      for bread, idx in @props.bread_arr
        text = bread.text || bread.from
        nav_params = @props.nav_params[0...idx]
        <span className='bread' key={idx}>
        {
          if idx == @props.bread_arr.length - 1
            <span>{text}</span>
          else
            <a href='javascript:;' onClick={@nav_to(nav_params)}>
              {
                if idx == 0
                  <i className='icon home' />
              }
              {text}
            </a>
        }
        </span>
    }
    </div>

  nav_to: (nav_params)->
    =>
      @props.reader.nav_to(nav_params)


NodeContent = React.createClass
  render: ->
    current_node = @props.node

    <div>
    {
      title = current_node.text || current_node.from
      <div className='title-content'>
        <h2 className='ui header node-title'>{title}</h2>
        <a href='javascript:;' className='ui button labeled icon green mini add-fav'>
          <i className='icon plus' /> 添加关注
        </a>
        <div className='read-stat'>188 人读过</div>
        <QRCode key={location.href} ref='qrcode' />
        {
          if current_node.define?
            <div className='define'>{current_node.define}</div>
        }
      </div>
    }
    {
      if current_node.target?
        <div className='target-content'>
          <h3 className='ui header'>认知目标：{current_node.target}</h3>
        </div>
    }
    {
      for resource, idx in current_node.resources || []
        <Resource key={resource.name} data={resource} />
    }
    {
      if (current_node.resources || []).length is 0
        <div className='no-define'>
          本页面目前没有内容，你可先通过右上角进行关注，<br/>
          一旦内容更新，将第一时间发送提醒信息。<br/><br/>
          你也可以在下方留言提交建议：<br/><br/>
          <div className='ui form'>
            <div className='field'>
              <textarea placeholder='留下你的建议' rows='6' style={resize: 'none'}></textarea>
            </div>
          </div>
        </div>
    }
    {
      if current_node.paths?
        <div className='paths-content'>
          <h3 className='ui header'>进一步了解：</h3>
          <div className='paths'>
          {
            for path, idx in current_node.paths
              <PathNodesContent key={idx} path_idx={idx} path={path} reader={@props.reader} />
          }
          </div>
        </div>
    }
    </div>

QRCode = React.createClass
  getInitialState: ->
    url: null

  render: ->
    if @state.url?
      <div className='qrcode'>
        <div className='desc'>手机扫码访问</div>
        <img src={@state.url} />
      </div>
    else
      <div></div>

  componentDidMount: ->
    @refresh()

  refresh: ->
    jQuery.ajax
      type: 'post'
      url: 'http://s.4ye.me/parse'
      data:
        long_url: location.href
    .done (res)=>
      @setState url: res.qrcode



Resource = React.createClass
  render: ->
    resource = @props.data

    <div className='resource-content'>
    {
      switch resource.type
        when 'inline'
          <Resource.Inline resource={resource} />
        when 'images'
          <ImagesSlide resource={resource} />
    }
    </div>

  statics:
    Inline: React.createClass
      getInitialState: ->
        content: __html: ''
      render: ->
        resource = @props.resource

        <div className='inline'>
          <h4 className='ui header'>{resource.name}</h4>
          <div className='md-content' dangerouslySetInnerHTML={@state.content}>
          </div>
        </div>

      componentDidMount: ->
        jQuery.ajax
          url: "/getmd"
          data:
            file: @props.resource.file
        .done (res)=>
          content = marked(res)
          @setState content: __html: content

    # Images: React.createClass
    #   getInitialState: ->
    #     image_urls: ('http://i.teamkn.com/i/um1dRn8J.png' for i in [1..40])
    #   render: ->
    #     resource = @props.resource

    #     <div className='images'>
    #       <h4 className='ui header'>{resource.name}</h4>
    #       <div className='imgs'>
    #       {
    #         for url, idx in @state.image_urls
    #           _url = "#{url}?imageMogr2/thumbnail/!100x100r/gravity/Center/crop/100x100"
    #           <a className='img' target='_blank' href={url}>
    #             <img key={idx} src={_url} />
    #           </a>
    #       }
    #       </div>
    #     </div>

    #   componentDidMount: ->
    #     jQuery.ajax
    #       url: "/getimgs"
    #       data:
    #         file: @props.resource.file
    #     .done (res)=>
    #       @setState image_urls: res


Sharebar = React.createClass
  render: ->
    <div className='share-bar'>
      <div className='shares'>
        <a href='javascript:;' className='s'><i className='icon wechat' style={color: '#84C40E'} /> 分享到微信</a>
        <a href='javascript:;' className='s'><i className='icon weibo' style={color: '#E6162D'} /> 分享到微博</a>
        <a href='javascript:;' className='s'><i className='icon share' /> 其他</a>
      </div>
    </div>

PathNodesContent = React.createClass
  render: ->
    <div className='path-nodes-content'>
      <i className='headicon icon arrow right' />
      <div className='nodes'>
      {
        for node, idx in @props.path.nodes
          title = node.text || node.from
          nav_param = "#{@props.path_idx}:#{idx}"

          <a key={idx} className='path-node' href='javascript:;' onClick={@reader_nav_into(nav_param)}>
            {title}
          </a>
      }
      </div>
    </div>

  reader_nav_into: (nav_param)->
    =>
      @props.reader.nav_into(nav_param)