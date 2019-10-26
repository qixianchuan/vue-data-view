<template>
    <div class="chart">
        <vue-draggable-resizable :x="x"
                                 :y="y"
                                 :w="width"
                                 :h="height"
                                 @dragging="(left, top) =>onDrag('<%- config.chartId%>',left,top)"
                                 @resizing="(x, y, width, height) =>onResize('<%- config.chartId%>',x, y, width, height)"
                                 @activated="onActivated('<%- config.chartId%>')">
            <div @click="deleteChart('<%- config.chartId%>')" class="delete">删除</div>
            <div class="chart" ref="<%- config.chartId%>"
                               style="width: <%- config.config.width%>px;height:<%- config.config.height%>px;"
                               data-width="<%- config.config.width%>" data-height="<%- config.config.height%>" data-x="<%- config.config.dx%>" data-y="<%- config.config.dy%>"></div>
        </vue-draggable-resizable>
    </div>
</template>
<script>
    import './chart.styl'
    let echarts = require('echarts')
    import {getChartData} from "api/bar"
    import {getCommonConfig} from "common/js/normalize"
    import {socket} from "common/js/socket-client"
    import jsonobj from "common/js/chalk.project.json"
    import {mapGetters,mapMutations} from 'vuex'
    import {baseConfigApi} from 'common/js/config'
    export default {
        data(){
            return {
                x:0,
                y:0,
                width:10,
                height:10,
                chartId:'<%- config.chartId%>'
            }
        },
        mounted() {
            let mconfig = <%- JSON.stringify(config)%>
            this.commonConfig = mconfig.config.commonConfig
            this.userConfig = mconfig.config.userConfig
            this.dataUrl = mconfig.config.dataUrl
            this.chartType = <%- config.chartType%>
            echarts.registerTheme('chalk',jsonobj)
            this.$echarts = echarts.init(this.$refs.<%- config.chartId%>, 'chalk', {
                width: mconfig.config.width,
                height: mconfig.config.height
            })
            //this.$echarts.showLoading('default')
            getChartData(this.dataUrl).then((res)=>{
                //this.$echarts.hideLoading()
                let tempConfig = getCommonConfig(res.data,this.commonConfig,this.userConfig,this.chartType)
                this.$echarts.setOption(tempConfig)
                this.x = mconfig.config.dx
                this.y = mconfig.config.dy
                this.width = mconfig.config.width
                this.height = mconfig.config.height
                this.setPosition({id:'<%- config.chartId%>',x:mconfig.config.dx,y:mconfig.config.dy,width:mconfig.config.width,height:mconfig.config.height,xData:'',yData:[],yFields:[],dataId:''})
            })
        },
        computed:{
             ...mapGetters(
                ['storePosition','increaseId','increaseIdForData']
             )
        },
        watch:{
            increaseId(){
                let pos = this.storePosition(this.chartId)
                if(this.x != pos.x){
                    this.x = pos.x
                }
                if(this.y != pos.y){
                    this.y = pos.y
                }
                if(this.width != pos.width){
                    this.width = pos.width
                    this.$echarts.resize({width:pos.width})
                }
                if(this.height != pos.height){
                    this.height = pos.height
                }
            },
            increaseIdForData(){
                this._refreshData()
            }
        },
        methods:{
            _refreshData(){
                let pos = this.storePosition(this.chartId)
                if(!pos.xData || pos.yData.length === 0 || pos.yFields.length === 0 || !pos.dataId){
                    return
                }
                let dataUrl = `${baseConfigApi}/api/getChartDataDynamic?id=${pos.dataId}`
                getChartData(dataUrl).then((res)=>{
                    this.userConfig.x = pos.xData
                    this.userConfig.y = pos.yFields
                    let tempConfig = getCommonConfig(res.data,this.commonConfig,this.userConfig,this.chartType)
                    this.$echarts.clear()
                    console.log(tempConfig)
                    this.$echarts.setOption(tempConfig)
                })
            },
            onDrag(id,x,y){
                let position = {
                   dx:x,
                   dy:y,
                   chartId:id
                }
                this.setPosition({id:this.chartId,x:x,y:y,width:this.width,height:this.height})
                socket.emit('onDragInPanel',JSON.stringify(position))
            },
            onResize(id,x,y,width,height){
               let position = {
                   dx:x,
                   dy:y,
                   width:width,
                   height:height,
                   chartId:id
               }
               this.setPosition({id:this.chartId,x:x,y:y,width:width,height:height})
               this.$echarts.resize({width:width,height:height})
               socket.emit('onDragInPanel',JSON.stringify(position))
            },
            deleteChart(id){
                socket.emit('onDragRemove',id)
            },
            onActivated(id){
                this.setChartId(id)
                this.setIncreaseId(this.increaseId+1)
            },
            ...mapMutations({
                setChartId:'SET_CHART_ID',
                setPosition:'SET_POSITION',
                setIncreaseId:'SET_INCREASE_ID',
                setIncreaseUpdateData:'SET_INCREASE_UPDATE_DATA'
            })
        }
    }
</script>